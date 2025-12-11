<?php

declare(strict_types=1);

/**
 * Copyright (c) 2019.
 * Author:Alone88
 * Github:https://github.com/anhao
 */

namespace App\Services\Gateway;

use App\Models\Config;
use App\Models\Invoice;
use App\Models\Paylist;
use App\Services\Auth;
use App\Services\Gateway\Epay\EpayNotify;
use App\Services\Gateway\Epay\EpaySubmit;
use App\Services\Gateway\Epay\EpayTool;
use App\Services\View;
use Exception;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\GuzzleException;
use Psr\Http\Message\ResponseInterface;
use Slim\Http\Response;
use Slim\Http\ServerRequest;
use voku\helper\AntiXSS;
use function json_decode;
use function trim;

final class Epay extends Base
{
    protected array $epay = [];

    public function __construct()
    {
        $this->antiXss = new AntiXSS();
        $this->epay['apiurl'] = Config::obtain('epay_url');//易支付API地址
        $this->epay['partner'] = Config::obtain('epay_pid');//易支付商户pid
        $this->epay['key'] = Config::obtain('epay_key');//易支付商户Key
        $this->epay['sign_type'] = strtoupper(Config::obtain('epay_sign_type')); //签名方式
        $this->epay['input_charset'] = strtolower('utf-8');//字符编码
        $this->epay['transport'] = 'https';//协议 http 或者https
    }

    public static function _name(): string
    {
        return 'epay';
    }

    public static function _enable(): bool
    {
        return self::getActiveGateway('epay');
    }

    public static function _readableName(): string
    {
        return 'EPay';
    }

    public function purchase(ServerRequest $request, Response $response, array $args): ResponseInterface
    {   
		$price = $this->antiXss->xss_clean($request->getParam('price'));
        $invoice_id = $this->antiXss->xss_clean($request->getParam('invoice_id'));
        // EPay 特定参数
        $type = $this->antiXss->xss_clean($request->getParam('type'));
        $redir = $this->antiXss->xss_clean($request->getParam('redir'));
        $invoice = (new Invoice())->find($invoice_id);

        if ($invoice === null) {
            return $response->withJson([
                'ret' => 0,
                'msg' => 'Invoice not found',
            ]);
        }

        $price = $invoice->price;

        if ($price <= 0) {
            return $response->withJson([
                'ret' => 0,
                'msg' => '非法的金额',
            ]);
        }

        $user = Auth::getUser();
        $pl = new Paylist();
        $pl->userid = $user->id;
        $pl->total = $price;
        $pl->invoice_id = $invoice_id;
        $pl->tradeno = self::generateGuid();


        $type_text = match ($type) {
            'qqpay' => 'QQ',
            'wxpay' => 'WeChat',
            'usdt' => 'USDT',
            default => 'Alipay',
        };

        $pl->gateway = self::_readableName() . ' ' . $type_text;

        $pl->save();
        //请求参数
        $data = [
            'pid' => trim($this->epay['partner']),
            'type' => $type,
            'out_trade_no' => $pl->tradeno,
            'notify_url' => self::getCallbackUrl(),
            'return_url' => $redir,
            'name' => $pl->tradeno,
            'money' => $price,
            'sitename' => $_ENV['appName'],
            'clientip' => $_SERVER['REMOTE_ADDR'],
        ];

        $epaySubmit = new EpaySubmit($this->epay);
        $data['sign'] = $epaySubmit->buildRequestMysign(EpayTool::argSort($data));
        $data['sign_type'] = $this->epay['sign_type'];
        $client = new Client();

        try {			
            $res = json_decode(
                $client->request(
                    'POST',
					// 使用 rtrim 确保去掉末尾可能存在的斜杠，然后手动补上一个斜杠
					rtrim($this->epay['apiurl'], '/') . '/mapi.php',
//                  $this->epay['apiurl'] . 'mapi.php',
                    ['form_params' => $data]
                )->getBody()->__toString(),
                true
            );

            if ($res['code'] !== 1 || ! isset($res['payurl'])) {
                // --- 修改开始：获取上游真实的错误信息 ---
                $upstreamMsg = $res['msg'] ?? '未返回错误信息';
                $debugData = json_encode($res, JSON_UNESCAPED_UNICODE);
                
                return $response->withJson([
                    'ret' => 0,
                    // 将上游的错误直接显示出来，方便调试
                    'msg' => "支付方拒绝: {$upstreamMsg} (调试数据: {$debugData})",
                ]);
                // --- 修改结束 ---
            }
            return $response->withHeader('HX-Redirect', $res['payurl']);
		//	return $response->withRedirect($res['payurl']);

        } catch (GuzzleException $e) {
			
            return $response->withJson([
                'ret' => 0,
                'msg'  => '请求支付失败2，网关错误：' . $e->getMessage(),				
            ]);
        }
    }

    public function notify($request, $response, $args): ResponseInterface
    {
        $epayNotify = new EpayNotify($this->epay);
        $verify_result = $epayNotify->verifyNotify();

        if ($verify_result) {
            if ($_GET['trade_status'] === 'TRADE_SUCCESS') {
                $this->postPayment($_GET['out_trade_no']);
                // EPay just fucking copied from Alipay's method of determining whether the payment is successful
                // which is retarded
                // https://pay.v8jisu.cn/doc.html
                return $response->write('success');
            }
        }

        return $response->write('failed');
    }

    /**
     * @throws Exception
     */
    public static function getPurchaseHTML(): string
    {
        return View::getSmarty()->fetch('gateway/epay.tpl');
    }
}
