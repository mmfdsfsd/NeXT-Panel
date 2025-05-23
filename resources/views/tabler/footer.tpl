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

<script src="//{$config['jsdelivr_url']}/npm/@tabler/core@latest/dist/js/tabler.min.js"></script>

<script>
    function showDialog(dialogId, message) {
        const dialog = document.getElementById(dialogId);
        const messageElement = dialog.querySelector('p');
        messageElement.textContent = message;

        dialog.classList.add('show');
        dialog.style.display = 'block';
        dialog.removeAttribute('aria-hidden');
        dialog.querySelectorAll('[data-bs-dismiss]').forEach(btn => {
            btn.onclick = () => {
                dialog.classList.remove('show');
                dialog.style.display = 'none';
                dialog.setAttribute('aria-hidden', 'true');
            };
        });
    }

    htmx.on("htmx:afterRequest", function(evt) {
        if (evt.detail.xhr.getResponseHeader('HX-Redirect')) {
            return;
        }

        let res = JSON.parse(evt.detail.xhr.response);

        if (evt.detail.elt.id === 'send-verify-email') {
            document.getElementById('send-verify-email').disabled = true;
        }

        if (res.ret === 1) {
            showDialog('success-dialog', res.msg);
        } else {
            showDialog('fail-dialog', res.msg);
        }
    });
</script>

{include file='live_chat.tpl'}

</body>

</html>
