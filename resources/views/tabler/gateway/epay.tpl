<div class="card-inner">
    <p class="card-heading"></p>
	<b>支付宝/微信支付</b>
    <form class="epay" name="epay" method="post">
        {if $public_setting['epay_alipay']}
        <button
		  class="btn btn-flat waves-attach"
		  hx-post="/user/payment/purchase/epay"
		  hx-swap="none"
		  hx-vals='js:{
			  invoice_id: {$invoice->id},
			  type: "alipay",
			  redir: window.location.href
		  }'
		  hx-on::after-request="
			if (event.detail.successful) {
				const res = JSON.parse(event.detail.xhr.responseText);
				if (res.ret === 1 && res.payurl) {
					window.open(res.payurl, '_blank');
					startPayStatusCheck();
				} else {
					alert('支付失败：' + (res.msg || '未知错误'));
				}
			} else {
				alert('网络请求失败');
			}
		  ">
		  <img src="/images/alipay.png" height="2px"/>
		</button>
        {/if}
		
        {if $public_setting['epay_wechat']}
        <button
		  class="btn btn-flat waves-attach"
		  hx-post="/user/payment/purchase/epay"
		  hx-swap="none"
		  hx-vals='js:{
			  invoice_id: {$invoice->id},
			  type: "wxpay",
			  redir: window.location.href
		  }'
		  hx-on::after-request="
			if (event.detail.successful) {
				const res = JSON.parse(event.detail.xhr.responseText);
				if (res.ret === 1 && res.payurl) {
					showWxPayQr(res.payurl);
					startPayStatusCheck();
				} else {
					alert('支付失败：' + (res.msg || '未知错误'));
				}
			} else {
				alert('网络请求失败');
			}
		  ">
		  <img src="/images/wechat.png" height="2px"/>
		</button>
		<div id="wxpay-qrcode-box" style="display:none; text-align:center; margin-top:15px;">
			<p><b>请使用微信扫一扫完成支付</b></p>
			<div id="wxpay-qrcode"></div>
		</div>
        {/if}
		
        {if $public_setting['epay_qq']}
        <button class="btn btn-flat waves-attach"
                hx-post="/user/payment/purchase/epay" hx-swap="none"
                hx-vals='js:{
                    invoice_id: {$invoice->id},
                    type: "qqpay",
                    redir: window.location.href
                }'>
            <img src="/images/qq.svg" height="2px"/>
        </button>
        {/if}
		
        {if $public_setting['epay_usdt']}
        <button class="btn btn-flat waves-attach"
                hx-post="/user/payment/purchase/epay" hx-swap="none"
                hx-vals='js:{
                    invoice_id: {$invoice->id},
                    type: "usdt",
                    redir: window.location.href
                }'
				hx-on::after-request="
					if(event.detail.successful) {						
						const responseData = JSON.parse(event.detail.xhr.responseText);
						if (responseData.ret === 1 && responseData.payurl) {
							window.open(responseData.payurl, '_blank');
							startPayStatusCheck();
						} else if (responseData.ret === 0) {
							// 处理后端返回的错误信息
							alert('支付失败: ' + responseData.msg);
						}
					} else {
						alert('网络请求失败');
					}
                ">
            <img src="/images/tdbpay.png" height="2px"/>
        </button>
        {/if}
    </form>
</div>

<script>
function showWxPayQr(url) {
    const box = document.getElementById('wxpay-qrcode-box');
    const qr = document.getElementById('wxpay-qrcode');

    qr.innerHTML = '';
    box.style.display = 'block';

    new QRCode(qr, {
        text: url,
        width: 220,
        height: 220
    });
}
</script>

<script>
let payCheckTimer = null;
let payTimeoutTimer = null;
let hasCheckedOnce = false;

const PAY_CHECK_INTERVAL = 5000;       // 5 秒检测一次
const PAY_MAX_DURATION  = 10 * 60 * 1000; // 10 分钟超时

function startPayStatusCheck() {
    if (payCheckTimer) return;

    hasCheckedOnce = false;

    // ① 启动轮询
    payCheckTimer = setInterval(() => {
        fetch(window.location.href, {
            cache: 'no-store',
            credentials: 'same-origin'
        })
        .then(res => res.text())
        .then(html => {

            // 精准匹配“账单状态”
            const match = html.match(
                /账单状态<\/div>\s*<div class="datagrid-content">([^<]+)<\/div>/
            );

            if (!match) return;

            const statusText = match[1].trim();

            // 第一次仅记录，防止误判
            if (!hasCheckedOnce) {
                hasCheckedOnce = true;
                return;
            }

            // 已支付
            if (statusText.includes('已支付')) {
                stopPayStatusCheck();
                alert('支付成功，页面即将刷新');
                location.reload();
            }
        })
        .catch(err => {
            console.warn('支付状态检测失败', err);
        });
    }, PAY_CHECK_INTERVAL);

    // ② 启动超时兜底
    payTimeoutTimer = setTimeout(() => {
        stopPayStatusCheck();
        alert('支付超时，如已完成支付请手动刷新页面');
    }, PAY_MAX_DURATION);
}

function stopPayStatusCheck() {
    if (payCheckTimer) {
        clearInterval(payCheckTimer);
        payCheckTimer = null;
    }
    if (payTimeoutTimer) {
        clearTimeout(payTimeoutTimer);
        payTimeoutTimer = null;
    }
}

// 页面关闭时清理
window.addEventListener('beforeunload', stopPayStatusCheck);
</script>
