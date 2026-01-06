<script src="//{$config['jsdelivr_url']}/npm/jquery/dist/jquery.min.js"></script>
<hr>
<div class="card-inner">
    <h4>
        支付宝支付
    </h4>
    <p class="card-heading"></p>
    <div id="f2f-qrcode" class="text-center"></div>
    <button class="btn btn-flat waves-attach" id="f2fpay-button" type="button" onclick="f2fpay();">
        <img src="/images/alipay.png" height="2px"/>
		点击付款
    </button>
</div>

<script>
    // 不再把变量名起名为 f2fQrcode，以免混淆，这里它只是个按钮
    let payButton = $('#f2fpay-button');

    function f2fpay() {
        $.ajax({
            type: "POST",
            url: "/user/payment/purchase/f2f",
            dataType: "json",
            data: {
                invoice_id: {$invoice->id},
            },
            success: (data) => {
                if (data.ret === 1) {
                    // 1. 移除按钮
                    payButton.remove();

                    // 2. 获取二维码容器
                    let qrContainer = $('#f2f-qrcode');

                    // 3. 在生成二维码之前，先加一行提示文字
                    qrContainer.append('<div><p>打开手机支付宝扫描支付</p></div>');

                    // 4. 生成二维码 (QRCode 库会将 canvas/img 插入到 #f2f-qrcode 内部)
                    new QRCode("f2f-qrcode", {
                        text: data.qrcode,
                        width: 200,
                        height: 200,
                        colorDark: '#000000',
                        colorLight: '#ffffff',
                        correctLevel: QRCode.CorrectLevel.H,
                    });

                    // 5. 【关键修复】将提示文字 append 到二维码容器中，而不是已删除的按钮
                    qrContainer.append('<div class="my-3"><p>支付成功后请手动刷新页面</p></div>');
                    
                } else {
                    $('#fail-message').text(data.msg);
                    $('#fail-dialog').modal('show');
                }
            }
        })
    }
</script>
