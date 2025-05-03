<div class="modal modal-blur fade" id="success-dialog" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-sm modal-dialog-centered" role="document">
        <div class="modal-content">
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            <div class="modal-status bg-success"></div>
            <div class="modal-body text-center py-4">
                <i class="ti ti-circle-check icon mb-2 text-green icon-lg" style="font-size:3.5rem;"></i>
                <p id="success-message" class="text-secondary">成功</p>
            </div>
            <div class="modal-footer">
                <div class="w-100">
                    <div class="row">
                        <div class="col">
                            <a id="success-confirm" href="" class="btn w-100" data-bs-dismiss="modal">
                                好
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="modal modal-blur fade" id="fail-dialog" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-sm modal-dialog-centered" role="document">
        <div class="modal-content">
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            <div class="modal-status bg-danger"></div>
            <div class="modal-body text-center py-4">
                <i class="ti ti-circle-x icon mb-2 text-danger icon-lg" style="font-size:3.5rem;"></i>
                <p id="fail-message" class="text-secondary">失败</p>
            </div>
            <div class="modal-footer">
                <div class="w-100">
                    <div class="row">
                        <div class="col">
                            <a href="" class="btn btn-danger w-100" data-bs-dismiss="modal">
                                确认
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<footer class="footer footer-transparent d-print-none">
    <div class="container-xl">
        <div class="row text-center align-items-center flex-row-reverse">
            <div class="col-lg-auto ms-lg-auto">
                <ul class="list-inline list-inline-dots mb-0">
                    <li class="list-inline-item">
                        Powered by <a href="/staff" class="link-secondary">NeXT Panel</a>
                        <!-- 删除staff是不尊重每一位开发者的行为 -->
                    </li>
                </ul>
            </div>
        </div>
    </div>
</footer>
</div>
</div>
<!-- 模态框触发器（隐藏按钮） -->
<button id="trigger-success-dialog" type="button" class="d-none" data-bs-toggle="modal" data-bs-target="#success-dialog"></button>
<button id="trigger-fail-dialog" type="button" class="d-none" data-bs-toggle="modal" data-bs-target="#fail-dialog"></button>

<div id="toast" class="toast-message">已复制到剪贴板</div>
<!-- js -->
<script src="//{$config['jsdelivr_url']}/npm/@tabler/core@latest/dist/js/tabler.min.js"></script>
<script>
    const toast = document.getElementById("toast");
    const clipboard = new ClipboardJS('.copy');
    clipboard.on('success', function(e) {
      showToast("✅ 已复制：" + e.text);
    });
    clipboard.on('error', function() {
      showToast("❌ 复制失败，请手动复制");
    });

    function showToast(message) {
      toast.textContent = message;
      toast.classList.add("show");
      setTimeout(() => {
        toast.classList.remove("show");
      }, 3000);
    }

    htmx.on("htmx:afterRequest", function(evt) {
    if (evt.detail.xhr.getResponseHeader('HX-Refresh') === 'true' ||
        evt.detail.xhr.getResponseHeader('HX-Redirect') ||
        evt.detail.xhr.getResponseHeader('HX-Trigger')) {
        return;
    }

    let res;
    try {
        res = JSON.parse(evt.detail.xhr.response);
    } catch (e) {
        console.error("响应解析失败:", e);
        return;
    }

    // 动态填充字段内容
    if (typeof res.data !== 'undefined') {
        for (let key in res.data) {
            if (res.data.hasOwnProperty(key)) {
                if (key === "ga-url" && typeof qrcode !== 'undefined') {
                    qrcode.clear();
                    qrcode.makeCode(res.data[key]);
                }

                if (key === "last-checkin-time") {
                    const checkInBtn = document.getElementById("check-in");
                    if (checkInBtn) {
                        checkInBtn.innerHTML = "已签到";
                        checkInBtn.disabled = true;
                    }
                }

                const element = document.getElementById(key);
                if (element) {
                    if (element.tagName === "INPUT" || element.tagName === "TEXTAREA") {
                        element.value = res.data[key];
                    } else {
                        element.innerHTML = res.data[key];
                    }
                }
            }
        }
    }

    // 显示模态框：成功或失败
    if (res.ret === 1) {
        document.getElementById("success-message").textContent = res.msg || "操作成功";
        document.getElementById("trigger-success-dialog").click();
    } else {
        document.getElementById("fail-message").textContent = res.msg || "操作失败";
        document.getElementById("trigger-fail-dialog").click();
    }
    });
</script>
<script>console.table([['数据库查询', '执行时间'], ['{count($queryLog)} 次', '{$optTime} ms']])</script>

{include file='live_chat.tpl'}

</body>

</html>
