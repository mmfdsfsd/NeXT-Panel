<div class="card-inner">
    <h4>
        EPay
    </h4>
    <p class="card-heading"></p>
    <form class="epay" name="epay" method="post">
        {if $public_setting['epay_alipay']}
        <button class="btn btn-flat waves-attach"
                hx-post="/user/payment/purchase/epay" hx-swap="none"
                hx-vals='js:{
                    invoice_id: {$invoice->id},
                    type: "alipay",
                    redir: window.location.href
                }'>
            <img src="/images/alipay.svg" height="50px"/>
        </button>
        {/if}
        {if $public_setting['epay_wechat']}
        <button class="btn btn-flat waves-attach"
                hx-post="/user/payment/purchase/epay" hx-swap="none"
                hx-vals='js:{
                    invoice_id: {$invoice->id},
                    type: "wxpay",
                    redir: window.location.href
                }'>
            <img src="/images/wechat.svg" height="50px"/>
        </button>
        {/if}
        {if $public_setting['epay_qq']}
        <button class="btn btn-flat waves-attach"
                hx-post="/user/payment/purchase/epay" hx-swap="none"
                hx-vals='js:{
                    invoice_id: {$invoice->id},
                    type: "qqpay",
                    redir: window.location.href
                }'>
            <img src="/images/qq.svg" height="50px"/>
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
						// 解析JSON响应体
						const responseData = JSON.parse(event.detail.xhr.responseText);
						if (responseData.ret === 1 && responseData.payurl) {
							// 使用解析出的 payurl 打开新窗口
							window.open(responseData.payurl, '_blank');
						} else if (responseData.ret === 0) {
							// 处理后端返回的错误信息
							alert('支付失败: ' + responseData.msg);
						}
					} else {
						alert('网络请求失败');
					}
                ">
            <img src="/images/tether.svg" height="50px"/>
        </button>
        {/if}
    </form>
</div>
