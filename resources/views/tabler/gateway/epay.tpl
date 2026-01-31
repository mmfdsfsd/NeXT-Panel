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
let hasCheckedOnce = false; // 关键：防止首次加载误判

function startPayStatusCheck() {
    if (payCheckTimer) return;

    payCheckTimer = setInterval(() => {
        fetch(window.location.href, {
            cache: 'no-store',
            credentials: 'same-origin'
        })
        .then(res => res.text())
        .then(html => {

            // 1️⃣ 精准匹配“账单状态”这一栏
            const match = html.match(
                /账单状态<\/div>\s*<div class="datagrid-content">([^<]+)<\/div>/
            );

            if (!match) return;

            const statusText = match[1].trim();

            // 2️⃣ 第一次只记录状态，不做任何动作
            if (!hasCheckedOnce) {
                hasCheckedOnce = true;
                return;
            }

            // 3️⃣ 后续轮询才允许触发
            if (statusText.includes('已支付')) {
                clearInterval(payCheckTimer);
                payCheckTimer = null;

                alert('支付成功，页面即将刷新');
                location.reload();
            }
        })
        .catch(err => {
            console.warn('支付状态检测失败', err);
        });
    }, 5000); // 5 秒一次，稳定不炸
}

window.addEventListener('beforeunload', () => {
    if (payCheckTimer) {
        clearInterval(payCheckTimer);
    }
});
</script>
