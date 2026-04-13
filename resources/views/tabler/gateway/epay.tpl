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
						// pc端使用 window.open 在新窗口打开，'_blank' 参数表示新标签页
						const newWindow = window.open(res.payurl, '_blank');
						startPayStatusCheck(res.tradeno);
						// 兼容性检查：如果浏览器拦截了弹窗（例如用户未点击直接触发）
						if (!newWindow || newWindow.closed || typeof newWindow.closed === 'undefined') {
							// 如果被拦截，降级为当前页面跳转，或者提示用户
							window.location.href = res.payurl;
						}					
												
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
			<!--
			<div id="alipay-qrcode-box" style="display:none; text-align:center; margin-top:15px;">
				<p><b>请使用支付宝扫码完成支付</b></p>
				<div id="alipay-qrcode"></div>
			</div>  -->
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
								// 处理后端返回的错误信息
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
		colorLight: "#FFFFFF"
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

function startPayStatusCheck(tradeno) {
    // --- 调试信息开始 ---
    console.log("初始化支付检测...");
    console.log("接收到的订单号 (tradeno):", tradeno);
    
    if (!tradeno || tradeno === 'undefined') {
        console.error("错误：未能获取到有效的 tradeno，请检查后端接口返回内容。");
        return;
    }
    // --- 调试信息结束 ---

    if (payCheckTimer) clearInterval(payCheckTimer);

    let count = 0; 
    const maxAttempts = 120; 

    payCheckTimer = setInterval(() => {
        count++;
        console.log(`[轮询检测] 第 ${count} 次询问订单 ${tradeno} 的状态...`);

        if (count > maxAttempts) {
            clearInterval(payCheckTimer);
            console.log("检测超时，已停止。");
            return;
        }

        fetch(`/user/payment/status?tradeno=${tradeno}&t=${Date.now()}`)
            .then(res => {
                if (!res.ok) throw new Error('网络响应异常: ' + res.status);
                return res.json();
            })
            .then(data => {
                if (data.ret === 1 && data.is_paid === true) {
                    console.log("检测成功：订单已支付！");
                    clearInterval(payCheckTimer);
                    alert('支付成功！');
                    location.reload();
                }
            })
            .catch(err => console.warn('轮询请求出错:', err));
    }, 5000);
}
</script>
{/literal}

{literal}
<script>
let payCheckTimer = null;

// 绿色提示框：水平居中显示
function showSuccessToast() {
    const toast = document.createElement('div');
    toast.innerHTML = '<strong>✓ 支付成功</strong><br>正在为您跳转...';
    
    // 设置居中样式
    const styles = {
        position: 'fixed',
        top: '20%',           // 距离顶部 20% 的位置，看起来更显眼
        left: '50%',          // 移动到屏幕水平正中间
        transform: 'translateX(-50%)', // 关键：向左偏移自身宽度的 50%，实现完美居中
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

    // 循环赋值，避免直接在 Object.assign 中写大括号引起 Smarty 误判
    for (const key in styles) {
        toast.style[key] = styles[key];
    }

    document.body.appendChild(toast);
}

function startPayStatusCheck(tradeno) {
    if (payCheckTimer) clearInterval(payCheckTimer);

    payCheckTimer = setInterval(() => {
        fetch(`/user/payment/status?tradeno=${tradeno}&t=${Date.now()}`)
            .then(res => res.json())
            .then(data => {
                if (data.ret === 1 && data.is_paid === true) {
                    clearInterval(payCheckTimer);
                    
                    // 显示居中的成功提示
                    showSuccessToast();
                    
                    setTimeout(() => {
                        location.reload();
                    }, 1500);
                }
            })
            .catch(err => console.warn('检测出错:', err));
    }, 5000);
}
</script>
{/literal}
