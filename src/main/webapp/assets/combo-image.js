(() => {
    const input=document.getElementById('comboImage');
    const preview=document.getElementById('comboImagePreview');
    if (!input || !preview) return;
    const previous=preview.getAttribute('src');
    let temporary;
    input.addEventListener('change', () => {
        if (temporary) URL.revokeObjectURL(temporary);
        const file=input.files[0];
        if (file && (file.size>5*1024*1024 || !['image/png','image/jpeg'].includes(file.type))) {
            input.value=''; alert('Chọn ảnh PNG hoặc JPEG tối đa 5 MB.');
            preview.src=previous; preview.hidden=!previous; return;
        }
        preview.src=file ? (temporary=URL.createObjectURL(file)) : previous;
        preview.hidden=!file && !previous;
    });
})();
