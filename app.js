// Initialize map centered on Osório, RS
const map = L.map('map').setView([-29.8875, -50.2697], 14);

// Add OpenStreetMap tiles
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
}).addTo(map);

// Custom pothole icon
const potholeIcon = L.divIcon({
    className: 'pothole-marker',
    html: '🕳️',
    iconSize: [36, 36],
    iconAnchor: [18, 18],
    popupAnchor: [0, -18]
});

// Load potholes data
let potholes = [];

async function loadPotholes() {
    try {
        const response = await fetch('data.json');
        potholes = await response.json();

        // Update counter
        document.getElementById('pothole-count').textContent = potholes.length;

        // Add markers to map
        potholes.forEach(pothole => {
            const marker = L.marker([pothole.lat, pothole.lng], { icon: potholeIcon })
                .addTo(map);

            marker.on('click', () => showPotholeInfo(pothole));
        });
    } catch (error) {
        console.error('Erro ao carregar dados:', error);
    }
}

// Show pothole information in sidebar
function showPotholeInfo(pothole) {
    const infoCard = document.getElementById('pothole-info');
    const photo = document.getElementById('pothole-photo');
    const address = document.getElementById('pothole-address');
    const reporter = document.getElementById('pothole-reporter');
    const date = document.getElementById('pothole-date');

    photo.src = pothole.photo;
    photo.alt = `Buraco na ${pothole.address}`;
    address.textContent = pothole.address;
    reporter.textContent = pothole.reporter;
    date.textContent = formatDate(pothole.date);

    infoCard.style.display = 'block';

    // Scroll to info card on mobile
    if (window.innerWidth <= 768) {
        infoCard.scrollIntoView({ behavior: 'smooth' });
    }
}

// Close info card
document.getElementById('close-info').addEventListener('click', () => {
    document.getElementById('pothole-info').style.display = 'none';
});

// Format date to Brazilian format
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('pt-BR', {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
    });
}

// Animate counter
function animateCounter(element, target) {
    let current = 0;
    const increment = target / 30;
    const timer = setInterval(() => {
        current += increment;
        if (current >= target) {
            element.textContent = target;
            clearInterval(timer);
        } else {
            element.textContent = Math.floor(current);
        }
    }, 50);
}

// Initialize
loadPotholes().then(() => {
    const counter = document.getElementById('pothole-count');
    const target = parseInt(counter.textContent);
    counter.textContent = '0';
    animateCounter(counter, target);
});
