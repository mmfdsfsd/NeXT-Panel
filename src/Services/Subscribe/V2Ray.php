<?php

declare(strict_types=1);

namespace App\Services\Subscribe;

use App\Models\Config;
use App\Services\Subscribe;
use function base64_encode;
use function json_decode;
use function json_encode;
use const PHP_EOL;

final class V2Ray extends Base
{
    public function getContent($user): string
    {
        $links = '';
        //判断是否开启V2Ray订阅
        if (! Config::obtain('enable_v2_sub')) {
            return $links;
        }

        $nodes_raw = Subscribe::getUserNodes($user);
        
        // 在 VMess 链接输出之前，添加 SOCKS5 Base64 编码链接 username:passwd@IP:port#name
	$links .= 'socks://bW10aS5vbmU6bW10aS5vbmU=@guanwang.awsno.com:1080#打不开官网时请选我👈'. PHP_EOL;
        
        foreach ($nodes_raw as $node_raw) {
            $node_custom_config = json_decode($node_raw->custom_config, true);

            if ((int) $node_raw->sort === 11) {
                $v2_port = $node_custom_config['offset_port_user'] ?? ($node_custom_config['offset_port_node'] ?? 443);
                $security = $node_custom_config['security'] ?? 'none';
                $network = $node_custom_config['network'] ?? '';
                $header = $node_custom_config['header'] ?? ['type' => 'none'];
                $header_type = $header['type'] ?? '';
                $host = $node_custom_config['header']['request']['headers']['Host'][0] ?? $node_custom_config['host'] ?? '';
                $path = $node_custom_config['header']['request']['path'][0] ?? $node_custom_config['path'] ?? '/';

                $v2rayn_array = [
                    'v' => '2',
                    'ps' => $node_raw->name,
                    'add' => $node_raw->server,
                    'port' => $v2_port,
                    'id' => $user->uuid,
                    'aid' => 0,
                    'net' => $network,
                    'type' => $header_type,
                    'host' => $host,
                    'path' => $path,
                    'tls' => $security,
					'allowInsecure' => '1',  //新增
                ];

                $links .= 'vmess://' . base64_encode(json_encode($v2rayn_array)) . PHP_EOL;
            }
			if ((int) $node_raw->sort === 14) {
                $trojan_port = $node_custom_config['offset_port_user'] ?? ($node_custom_config['offset_port_node'] ?? 443);
                $host = $node_custom_config['host'] ?? '';
                $allow_insecure = $node_custom_config['allow_insecure'] ?? '0';
                $security = $node_custom_config['security'] ?? 'tls';
                $mux = $node_custom_config['mux'] ?? '0';
                $network = $node_custom_config['network'] ?? 'tcp';
                $transport_plugin = $node_custom_config['transport_plugin'] ?? '';
                $transport_method = $node_custom_config['transport_method'] ?? '';
                $servicename = $node_custom_config['servicename'] ?? '';
                $path = $node_custom_config['path'] ?? '';

                $links .= 'trojan://' . $user->uuid . '@' . $node_raw->server . ':' . $trojan_port . '?peer=' . $host . '&sni='
                    . $host . '&obfs=' . $transport_plugin . '&path=' . $path . '&mux=' . $mux . '&allowInsecure='
                    . $allow_insecure . '&obfsParam=' . $transport_method . '&type=' . $network . '&security='
                    . $security . '&serviceName=' . $servicename . '#' . $node_raw->name . PHP_EOL;
            }
        }

        return $links;
    }
}
