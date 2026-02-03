// Initialize map centered on Osório, RS
const map = L.map('map').setView([-29.8875, -50.2697], 14);

// Add OpenStreetMap tiles
L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
}).addTo(map);

// Custom pothole icons
function createPotholeIcon(fixed) {
    return L.divIcon({
        className: `pothole-marker${fixed ? ' fixed' : ''}`,
        html: fixed ? '✓' : '🕳️',
        iconSize: [36, 36],
        iconAnchor: [18, 18],
        popupAnchor: [0, -18]
    });
}

// Store potholes and markers
let potholes = [];
let markers = {};

async function loadPotholes() {
    try {
        const response = await fetch('data.json');
        potholes = await response.json();

        // Update counter
        document.getElementById('pothole-count').textContent = potholes.length;

        // Add markers to map
        potholes.forEach(pothole => {
            const icon = createPotholeIcon(pothole.fixed);
            const marker = L.marker([pothole.lat, pothole.lng], { icon })
                .addTo(map);

            marker.on('click', () => {
                showPotholeInfo(pothole);
                updateURL(pothole.id);
            });

            // Store marker reference by pothole ID
            markers[pothole.id] = { marker, pothole };
        });

        // Check URL for specific pothole
        checkURLForPothole();
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
    const status = document.getElementById('pothole-status');

    photo.src = pothole.photo;
    photo.alt = `Buraco na ${pothole.address}`;
    address.textContent = pothole.address;
    reporter.textContent = pothole.reporter;
    date.textContent = formatDate(pothole.date);

    // Update status badge
    if (pothole.fixed) {
        status.textContent = 'Consertado';
        status.className = 'status-badge fixed';
    } else {
        status.textContent = 'Pendente';
        status.className = 'status-badge pending';
    }

    infoCard.style.display = 'block';

    // Scroll to info card on mobile
    if (window.innerWidth <= 768) {
        infoCard.scrollIntoView({ behavior: 'smooth' });
    }
}

// Update URL with pothole ID
function updateURL(id) {
    history.replaceState(null, null, `#buraco-${id}`);
}

// Check URL for pothole ID and open it
function checkURLForPothole() {
    const hash = window.location.hash;
    if (hash && hash.startsWith('#buraco-')) {
        const id = parseInt(hash.replace('#buraco-', ''));
        openPotholeById(id);
    }
}

// Open pothole by ID
function openPotholeById(id) {
    const data = markers[id];
    if (data) {
        const { marker, pothole } = data;

        // Center map on pothole with zoom
        map.setView([pothole.lat, pothole.lng], 17);

        // Show info
        showPotholeInfo(pothole);

        // Briefly highlight the marker
        const markerElement = marker.getElement();
        if (markerElement) {
            markerElement.style.transform = 'scale(1.3)';
            setTimeout(() => {
                markerElement.style.transform = '';
            }, 500);
        }
    }
}

// Listen for hash changes
window.addEventListener('hashchange', checkURLForPothole);

// Close info card
document.getElementById('close-info').addEventListener('click', () => {
    document.getElementById('pothole-info').style.display = 'none';
    history.replaceState(null, null, window.location.pathname);
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
