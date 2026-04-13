<div class="card-inner">
	<b>支付宝 / 微信 / USDT</b>
	<div class="mt-2">
		<form class="epay" name="epay" method="post" style="display:flex; flex-wrap:wrap; gap:12px;">
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
						const isMobile = /Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent);
						if (isMobile) {							
							window.location.href = res.payurl;
						} else {
							showAlipayQr(res.payurl);
						}						
						startPayStatusCheck(res.tradeno);				
					} else {
						alert('支付失败：' + (res.msg || '未知错误'));
					}
				} else {
					alert('网络请求失败');
				}
			  ">
			  <img src="/images/alipay.png"/>
			  支付宝(+1%手续费)
			</button>			
			<div id="alipay-qrcode-box" style="display:none; text-align:center; margin-top:15px;">
				<p><b>请使用支付宝扫码完成支付</b></p>
				<div id="alipay-qrcode"></div>
			</div> 
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
						startPayStatusCheck(res.tradeno);	
					} else {
						alert('支付失败：' + (res.msg || '未知错误'));
					}
				} else {
					alert('网络请求失败');
				}
			  ">
			  <img src="/images/wechat.png"/>
			  &nbsp;微信 (+2.5%手续费)
			</button>
			<div id="wxpay-qrcode-box" style="display:none; text-align:center; margin-top:15px;">
				<p><b>请使用微信扫一扫完成支付</b></p>
				<div id="wxpay-qrcode" class="wxpay-qrcode-container"></div>
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
				<img src="/images/qq.svg"/>
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
							const res = JSON.parse(event.detail.xhr.responseText);
							if (res.ret === 1 && res.payurl) {
								window.open(res.payurl, '_blank');
								startPayStatusCheck(res.tradeno);
							} else if (res.ret === 0) {								
								alert('支付失败: ' + res.msg);
							}
						} else {
							alert('网络请求失败');
						}
					">
				<img src="/images/tdbpay.png"/>
				&nbsp;&nbsp;USDT-( Trc20协议 )
			</button>
			{/if}
		</form>
	</div>
</div>

<script>
function showAlipayQr(url) {
    const box = document.getElementById('alipay-qrcode-box');
    const qr = document.getElementById('alipay-qrcode');

    qr.innerHTML = '';
    box.style.display = 'block';

    new QRCode(qr, {
        text: url,
        width: 220,
        height: 220,
		colorDark: "#4DA3FF",   
		colorLight: "#FFFFFF",
		correctLevel: QRCode.CorrectLevel.Q
    });
}
</script>
<script>
function showWxPayQr(url) {
    const box = document.getElementById('wxpay-qrcode-box');
    const qr = document.getElementById('wxpay-qrcode');

    qr.innerHTML = '';
    box.style.display = 'block';

    new QRCode(qr, {
        text: url,
        width: 220,
        height: 220,
        colorDark: "#4CD964",   
		colorLight: "#FFFFFF"
    });
}
</script>

{literal}
<script>
let payCheckTimer = null;

// 绿色提示框：水平居中显示
function showSuccessToast() {
    const toast = document.createElement('div');
    toast.innerHTML = '<strong>✓ 支付成功</strong><br>正在为您跳转...';
    
    const styles = {
        position: 'fixed',
        top: '20%',
        left: '50%',
        transform: 'translateX(-50%)',
        backgroundColor: '#4CAF50',
        color: 'white',
        padding: '16px 32px',
        borderRadius: '8px',
        boxShadow: '0 8px 24px rgba(0,0,0,0.2)',
        zIndex: '10000',
        textAlign: 'center',
        transition: 'all 0.5s ease',
        fontFamily: 'sans-serif',
        minWidth: '200px'
    };

    for (const key in styles) {
        toast.style[key] = styles[key];
    }

    document.body.appendChild(toast);
}

function startPayStatusCheck(tradeno) {
    if (payCheckTimer) clearInterval(payCheckTimer);

    let count = 0;             // 计数器初始化
    const maxAttempts = 120;   // 最大轮询 120 次 (10分钟)

    payCheckTimer = setInterval(() => {
        count++;
        // 调试：可以在控制台看到进度
        console.log(`第 ${count} 次检测订单: ${tradeno}`);

        // 检查是否超过最大次数
        if (count > maxAttempts) {
            clearInterval(payCheckTimer);
            console.warn("轮询超时，已停止检测。");
            return;
        }

        fetch(`/user/payment/status?tradeno=${tradeno}&t=${Date.now()}`)
            .then(res => res.json())
            .then(data => {
                if (data.ret === 1 && data.is_paid === true) {
                    // 支付成功，清除定时器
                    clearInterval(payCheckTimer);
                    
                    showSuccessToast();
                    
                    setTimeout(() => {
                        location.reload();
                    }, 1500);
                }
            })
            .catch(err => console.warn('检测出错:', err));
    }, 5000); // 5秒轮询一次
}
</script>
{/literal}
