const pages = [
    '01-intro.md',
    '02-local-setup.md',
    '03-cloud-storage.md',
    '04-cloud-sql.md',
    '05-cloud-run.md',
    '06-cicd.md',
    '07-conclusion.md'
];

let currentPage = 0;
const sliderTrack = document.getElementById('slider-track');
const prevBtn = document.getElementById('prev-btn');
const nextBtn = document.getElementById('next-btn');
const indicator = document.getElementById('page-indicator');

async function loadPages() {
    for (let i = 0; i < pages.length; i++) {
        const slide = document.createElement('div');
        slide.className = 'page-slide';
        
        const card = document.createElement('div');
        card.className = 'content-card';
        card.innerHTML = '<h2>Loading...</h2>';
        slide.appendChild(card);
        sliderTrack.appendChild(slide);

        fetch(`pages/${pages[i]}`)
            .then(res => {
                if (!res.ok) throw new Error('Failed to load ' + pages[i] + '. (Make sure to run this via a local server, e.g. python3 -m http.server)');
                return res.text();
            })
            .then(text => {
                card.innerHTML = marked.parse(text);
            })
            .catch(err => {
                card.innerHTML = `<h2>Error</h2><p>${err.message}</p>`;
            });
    }
}

function updateNavigation() {
    sliderTrack.style.transform = `translateX(-${currentPage * 100}%)`;
    prevBtn.disabled = currentPage === 0;
    nextBtn.disabled = currentPage === pages.length - 1;
    indicator.textContent = `${currentPage + 1} / ${pages.length}`;
}

prevBtn.addEventListener('click', () => {
    if (currentPage > 0) {
        currentPage--;
        updateNavigation();
    }
});

nextBtn.addEventListener('click', () => {
    if (currentPage < pages.length - 1) {
        currentPage++;
        updateNavigation();
    }
});

// Keyboard navigation
window.addEventListener('keydown', (e) => {
    if (e.key === 'ArrowRight' || e.key === 'Space') {
        if (currentPage < pages.length - 1) {
            currentPage++;
            updateNavigation();
        }
    } else if (e.key === 'ArrowLeft') {
        if (currentPage > 0) {
            currentPage--;
            updateNavigation();
        }
    }
});

// Initialize
loadPages();
