{include file='user/header.tpl'}

<div class="page-wrapper">
    <div class="container-xl">
        <div class="page-header d-print-none text-white">
            <div class="row align-items-center">
                <div class="col">
                    <h2 class="page-title">
                        <span class="home-title my-3">账单 #{$invoice->id}</span>
                    </h2>
                    <div class="page-pretitle">
                        <span class="home-subtitle">账单详情</span>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="page-body">
        <div class="container-xl">
            <div class="row row-cards">

                <!-- 左侧：账单信息 -->
                {if $invoice->status === 'unpaid' || $invoice->status === 'partially_paid'}
                <div class="col-sm-12 col-lg-9">
                {else}
                <div class="col-md-12">
                {/if}

                    <!-- 基本信息 -->
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">基本信息</h3>
                        </div>
                        <div class="card-body">
                            <div class="datagrid">
                                <div class="datagrid-item">
                                    <div class="datagrid-title">订单ID</div>
                                    <div class="datagrid-content">{$invoice->order_id}</div>
                                </div>
                                <div class="datagrid-item">
                                    <div class="datagrid-title">订单金额</div>
                                    <div class="datagrid-content">{$invoice->price}元</div>
                                </div>
                                <div class="datagrid-item">
                                    <div class="datagrid-title">订单状态</div>
                                    <div class="datagrid-content">{$invoice->status_text}</div>
                                </div>
                                <div class="datagrid-item">
                                    <div class="datagrid-title">创建时间</div>
                                    <div class="datagrid-content">{$invoice->create_time}</div>
                                </div>
                                <div class="datagrid-item">
                                    <div class="datagrid-title">更新时间</div>
                                    <div class="datagrid-content">{$invoice->update_time}</div>
                                </div>
                                <div class="datagrid-item">
                                    <div class="datagrid-title">支付时间</div>
                                    <div class="datagrid-content">{$invoice->pay_time}</div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 账单详情 -->
                    <div class="card my-3">
                        <div class="card-header">
                            <h3 class="card-title">账单详情</h3>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-vcenter card-table">
                                    <thead>
                                    <tr>
                                        <th>名称</th>
                                        <th>价格</th>
                                    </tr>
                                    </thead>
                                    <tbody>
                                    {foreach $invoice_content as $item}
                                    <tr>
                                        <td>{$item->name}</td>
                                        <td>{$item->price}</td>
                                    </tr>
                                    {/foreach}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>

                <!-- 右侧：支付区域 -->
                {if $invoice->status === 'unpaid' || $invoice->status === 'partially_paid'}
                <div class="col-sm-12 col-lg-3">

                    <!-- 💰 余额支付 -->
                    {if $invoice->type !== 'topup'}
                    <div class="card mb-3">
                        <div class="card-header">
                            <h3 class="card-title">
                                <i class="ti ti-coins"></i> 余额支付
                            </h3>
                        </div>
                        <div class="card-body">

                            <div class="mb-2">
                                当前余额：<code>{$user->money}</code> 元
                            </div>

                            {if $invoice->price <= $user->money}
                            <button id="payBtn"
                                    class="btn btn-primary w-100"
                                    hx-post="/user/invoice/pay_balance"
                                    hx-swap="none"
                                    hx-trigger="click once"
                                    hx-vals='js:{
                                        invoice_id: {$invoice->id},
                                    }'>
                                <i class="ti ti-coins"></i> &nbsp;使用余额支付
                            </button>
                            {else}
                            <div class="mt-2">
								<a href="/user/money" class="btn btn-warning w-100">
									<i class="ti ti-arrow-up-right"></i> 充值余额
								</a>
							</div>
                            {/if}

                        </div>
                    </div>
                    {/if}

                    <!-- 💳 在线支付 -->
                    {if count($payments) > 0}
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title">
                                <i class="ti ti-credit-card"></i> 在线支付
                            </h3>
                        </div>
                        <div class="card-body">

                            <div class="d-flex flex-column gap-2">
								{foreach from=$payments item=payment}
								<div class="card p-2 pay-card">
									{$payment_name = $payment::_name()}
									{include file="../../gateway/$payment_name.tpl"}
								</div>
								{/foreach}
							</div>

                        </div>
                    </div>
                    {/if}

                </div>
                {/if}

            </div>
        </div>
    </div>

{include file='user/footer.tpl'}

<style>
/* 支付按钮布局 */
.epay {
    display: flex;
    flex-wrap: wrap;
    gap: 10px;
}

.epay button {
    width: 100%;
    height: 42px;
    display: flex;
    align-items: center;
    justify-content: center;
}

/* 仅控制支付按钮图标 */
.epay > button > img.icon {
    height: 18px !important;
    margin-right: 6px;
}

/* 微信二维码容器 */
#wxpay-qrcode-box {
    display: none;
    text-align: center;
    margin-top: 15px;
}

#wxpay-qrcode {
    width: 220px !important;
    height: 220px !important;
}

/* 支付卡片 hover 动效 */
.pay-card {
    cursor: pointer;
    transition: all 0.2s ease;
}

.pay-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}
</style>

<script>
/* 防止重复点击 */
document.addEventListener('click', function (e) {
    const btn = e.target.closest('#payBtn');
    if (btn) {
        btn.disabled = true;
        btn.innerText = '支付处理中...';
    }
});
</script>
