<link rel="stylesheet"
      href="//{$config['jsdelivr_url']}/npm/@tabler/core@latest/dist/css/tabler-payments.min.css">
<div class="card-inner">  
    <div class="form-group form-group-label">
		<b>ApplePay / 银行卡 / 虚拟币</b>
		<div class="mt-2">
			<button class="btn btn-flat waves-attach" style="width: 100%; display: flex; justify-content: center; align-items: center;"
				hx-post="/user/payment/purchase/stripe" hx-swap="none"
				hx-vals='js:{
					invoice_id: {$invoice->id},
				}'>
				<img src="/images/applepay40.png" height="2px"/>&nbsp;&nbsp;
				<img src="/images/cardpay.png" height="2px"/>&nbsp;&nbsp;
				<img src="/images/usdc-30.png" height="2px"/>&nbsp;&nbsp;
			</button>
		</div>	
    </div>
	<div class="text-muted mt-2" style="font-size: 12px; text-align: center;">
            点击后可选择 ApplePay / 银行卡 / 虚拟币支付
    </div>
</div>
