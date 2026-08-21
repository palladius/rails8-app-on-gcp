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
const navList = document.getElementById('nav-list');
async function loadPages() {
    for (let i = 0; i < pages.length; i++) {
        const slide = document.createElement('div');
        slide.className = 'page-slide';
        
        const card = document.createElement('div');
        card.className = 'content-card';
        card.innerHTML = '<h2>Loading...</h2>';
        slide.appendChild(card);
        sliderTrack.appendChild(slide);

        // Pre-create navigation button
        const li = document.createElement('li');
        const navBtn = document.createElement('button');
        navBtn.id = `nav-btn-${i}`;
        navBtn.textContent = `...`;
        if (i === 0) navBtn.classList.add('active');
        navBtn.addEventListener('click', () => {
            currentPage = i;
            updateNavigation();
        });
        li.appendChild(navBtn);
        navList.appendChild(li);

        fetch(`pages/${pages[i]}`)
            .then(res => {
                if (!res.ok) throw new Error('Failed to load ' + pages[i] + '. (Make sure to run this via a local server, e.g. python3 -m http.server)');
                return res.text();
            })
            .then(text => {
                card.innerHTML = marked.parse(text);
                
                // Extract title from first H1, or use filename fallback
                const match = text.match(/^#\s+(.+)$/m);
                const title = match ? match[1] : pages[i].replace('.md', '').replace(/^\d+-/, '').replace(/-/g, ' ');
                navBtn.textContent = title;
            })
            .catch(err => {
                card.innerHTML = `<h2>Error</h2><p>${err.message}</p>`;
                navBtn.textContent = 'Error';
            });
    }
}

function updateNavigation() {
    sliderTrack.style.transform = `translateX(-${currentPage * 100}%)`;
    prevBtn.disabled = currentPage === 0;
    nextBtn.disabled = currentPage === pages.length - 1;
    indicator.textContent = `${currentPage + 1} / ${pages.length}`;
    
    // Update active class on nav links
    document.querySelectorAll('.nav-list button').forEach((btn, idx) => {
        if (idx === currentPage) {
            btn.classList.add('active');
        } else {
            btn.classList.remove('active');
        }
    });
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
