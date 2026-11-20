(() => {
    const select = document.getElementById('dishSizeId');
    if (!select) return;
    select.addEventListener('change', () => {
        const option = select.selectedOptions[0];
        if (!option) return;
        const price = document.getElementById('outPrice');
        const name = document.getElementById('currentSizeName');
        if (!price || !name) {
            select.form.requestSubmit();
            return;
        }
        // Use the exact formatted database price rendered by JSP; no floating-point calculation.
        price.textContent = option.dataset.price;
        name.textContent = option.dataset.size;
        const url = new URL(window.location.href);
        url.searchParams.set('dishSizeId', option.value);
        window.history.replaceState(null, '', url);
    });
})();
