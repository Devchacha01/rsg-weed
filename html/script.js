const RESOURCE_NAME = GetParentResourceName();

// Menu State
let currentMenuOptions = [];
let selectedIndex = 0;
let isMenuOpen = false;

// Quantity Modal State
let selectedItem = null;
let selectedPrice = 0;

// Plant State
let currentPlantId = null;

$(document).ready(function () {
    window.addEventListener('message', function (event) {
        let data = event.data;

        if (data.action === "openMenu") {
            openMenu(data.title, data.options, data.description);
        } else if (data.action === "closeMenu") {
            closeMenu();
        } else if (data.action === "openQuantityModal") {
            openQuantityModal(data.item, data.label, data.price);
        } else if (data.action === 'openPlant') {
            currentPlantId = data.plant.id;
            document.getElementById('plant-menu').classList.remove('hidden');
            updatePlantUI(data.plant);
        } else if (data.action === 'openSelling') {
            $('#sell-offer-text').html(`I'll give you <span class="highlight-price">$${data.price}</span> for <span class="highlight-item">${data.amount}x ${data.label}</span>.`);
            $('#selling-interaction').removeClass('hidden');
        } else if (data.action === 'close') {
            closePlantMenu();
            $('#selling-interaction').addClass('hidden');
        }
    });

    // Keyboard Navigation
    document.addEventListener('keydown', function (event) {
        if (isMenuOpen) {

            if (event.which == 37) { // Left
                selectedIndex--;
                if (selectedIndex < 0) selectedIndex = currentMenuOptions.length - 1;
                updateSelection();
            } else if (event.which == 39) { // Right
                selectedIndex++;
                if (selectedIndex >= currentMenuOptions.length) selectedIndex = 0;
                updateSelection();
            } else if (event.which == 38) { // Up
                selectedIndex -= 4;
                if (selectedIndex < 0) selectedIndex = 0;
                updateSelection();
            } else if (event.which == 40) { // Down
                selectedIndex += 4;
                if (selectedIndex >= currentMenuOptions.length) selectedIndex = currentMenuOptions.length - 1;
                updateSelection();
            } else if (event.which == 13) { // Enter
                selectOption();
            } else if (event.which == 8) { // Backspace
                closeMenu();
                $.post(`https://${RESOURCE_NAME}/closeMenu`, JSON.stringify({}));
            }
        }

        if (event.key === 'Escape') {
            if (!$('#quantity-modal').hasClass('hidden')) {
                closeQuantityModal();
            } else if (isMenuOpen) {
                closeMenu();
                $.post(`https://${RESOURCE_NAME}/closeMenu`, JSON.stringify({}));
            } else if (!$('#plant-menu').hasClass('hidden')) {
                closePlantMenu();
            }
        }
    });
});

/* Shop Menu Functions */
function openMenu(title, options, description) {
    $("#menu-title").text(title);

    if (description) {
        $("#menu-description").text(description).removeClass("hidden");
    } else {
        $("#menu-description").addClass("hidden");
    }

    $("#menu-options-list").empty();
    currentMenuOptions = options;
    selectedIndex = 0;

    options.forEach((opt, index) => {
        let imgHtml = '';
        if (opt.image) {
            imgHtml = `<div class="image-wrapper"><img src="${opt.image}" onerror="this.style.display='none'"></div>`;
        } else {
            imgHtml = `<div class="image-wrapper"><i class="fas fa-box fa-3x" style="color:#5d4037"></i></div>`;
        }

        let priceHtml = '';
        if (opt.price) {
            priceHtml = `<div class="price-badge">$${opt.price}</div>`;
        }

        let btnText = opt.btnLabel || "BUY";

        let el = $(`
            <div class="menu-option" id="opt-${index}">
                ${priceHtml}
                ${imgHtml}
                <div class="title">${opt.title}</div>
                <div class="buy-btn">${btnText}</div>
            </div>
        `);

        el.click(function () {
            selectedIndex = index;
            updateSelection();
            selectOption();
        });

        $("#menu-options-list").append(el);
    });

    updateSelection();
    $("#menu-interface").removeClass("hidden");
    isMenuOpen = true;
}

function updateSelection() {
    $(".menu-option").removeClass("selected");
    $(`#opt-${selectedIndex}`).addClass("selected");

    let el = document.getElementById(`opt-${selectedIndex}`);
    if (el) el.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
}

function selectOption() {
    let opt = currentMenuOptions[selectedIndex];
    if (opt) {
        $.post(`https://${RESOURCE_NAME}/selectOption`, JSON.stringify({
            index: selectedIndex + 1,
            data: opt
        }));
    }
}

function closeMenu() {
    $("#menu-interface").addClass("hidden");
    isMenuOpen = false;
}

/* Quantity Modal Functions */
function openQuantityModal(itemName, itemLabel, price) {
    selectedItem = { name: itemName, label: itemLabel };
    selectedPrice = price;

    $('#quantity-title').text(itemLabel);
    $('#qty-input').val(1);
    updateTotalPrice();
    $('#quantity-modal').removeClass('hidden');
}

function closeQuantityModal() {
    $('#quantity-modal').addClass('hidden');
    selectedItem = null;
}

function changeQty(delta) {
    let input = $('#qty-input');
    let val = parseInt(input.val()) + delta;
    if (val < 1) val = 1;
    if (val > 99) val = 99;
    input.val(val);
    updateTotalPrice();
}

function updateTotalPrice() {
    let qty = parseInt($('#qty-input').val()) || 1;
    $('#total-price').text((qty * selectedPrice).toFixed(2));
}

function confirmPurchase() {
    if (!selectedItem) return;

    let qty = parseInt($('#qty-input').val()) || 1;

    $.post(`https://${RESOURCE_NAME}/buyItem`, JSON.stringify({
        item: selectedItem.name,
        quantity: qty,
        price: selectedPrice * qty
    }));

    closeQuantityModal();
}

/* Plant Menu Functions (rsg-farming style) */
function updatePlantUI(plant) {
    if (!plant) return;

    // Strain label
    document.getElementById('plant-label').innerText = plant.label || 'Unknown Strain';

    // Growth
    const growth = Math.floor(plant.growth || 0);
    document.getElementById('growth-bar').style.width = growth + '%';
    document.getElementById('growth-percent').innerText = growth + '%';

    // Water
    const water = Math.floor(plant.water || 0);
    document.getElementById('water-bar').style.width = water + '%';
    document.getElementById('water-percent').innerText = water + '%';

    // Quality
    const quality = plant.quality || 100;
    document.getElementById('quality-bar').style.width = quality + '%';
    document.getElementById('quality-percent').innerText = quality + '%';

    // Time Remaining
    const timeRem = Math.ceil(plant.timeRemaining || 0);
    if (timeRem > 60) {
        const hours = Math.floor(timeRem / 60);
        const mins = timeRem % 60;
        document.getElementById('time-remaining').innerText = `${hours}h ${mins}m`;
    } else {
        document.getElementById('time-remaining').innerText = `${timeRem} min`;
    }

    // Status
    let status = 'Growing';
    if (water < 20) {
        status = '⚠️ Needs Water!';
    } else if (growth >= 100) {
        status = '✅ Ready to Harvest!';
    } else if (plant.fertilized == 1) {
        status = '⚡ Fertilized (Bonus Growth)';
    } else if (growth >= 50) {
        status = 'Maturing';
    }
    document.getElementById('plant-status').innerText = status;

    // Fertilize button state
    const fertilizeBtn = document.getElementById('fertilize-btn');
    if (fertilizeBtn) {
        if (plant.fertilized == 1 || growth >= 100) {
            fertilizeBtn.classList.add('disabled');
            fertilizeBtn.innerText = "Fertilized";
        } else {
            fertilizeBtn.classList.remove('disabled');
            fertilizeBtn.innerText = "Fertilize";
        }
    }

    // Water button state - disable when water is at 100%
    const waterBtn = document.getElementById('water-btn');
    if (waterBtn) {
        if (water >= 100) {
            waterBtn.classList.add('disabled');
        } else {
            waterBtn.classList.remove('disabled');
        }
    }

    // Harvest button availability
    const harvestBtn = document.getElementById('harvest-btn');
    if (growth >= 100) {
        harvestBtn.classList.remove('disabled');
    } else {
        harvestBtn.classList.add('disabled');
    }
}

function doAction(action) {
    if (!currentPlantId) return;

    $.post(`https://${RESOURCE_NAME}/plantAction`, JSON.stringify({
        plantId: currentPlantId,
        action: action
    }), function (data) {
        if (data.success) {
            if (data.newPlantData) updatePlantUI(data.newPlantData);
            if (data.message) showToast(data.message);
            if (action === 'destroy' || action === 'harvest') closePlantMenu();
        } else {
            if (data.message) showToast(data.message);
        }
    });
}

function closePlantMenu() {
    $('#plant-menu').addClass('hidden');
    $.post(`https://${RESOURCE_NAME}/close`, JSON.stringify({}));
}

function showToast(msg) {
    const t = document.getElementById('toast');
    if (t) {
        t.innerText = msg;
        t.classList.remove('hidden');
        setTimeout(() => {
            t.classList.add('hidden');
        }, 3000);
    }
}

function acceptOffer() {
    $('#selling-interaction').addClass('hidden');
    $.post(`https://${RESOURCE_NAME}/sell_accept`, JSON.stringify({}));
}

function declineOffer() {
    $('#selling-interaction').addClass('hidden');
    $.post(`https://${RESOURCE_NAME}/sell_decline`, JSON.stringify({}));
}
