let pages = [];
let currentPage = 0;
const sliderTrack = document.getElementById('slider-track');
const prevBtn = document.getElementById('prev-btn');
const nextBtn = document.getElementById('next-btn');
const indicator = document.getElementById('page-indicator');
const navList = document.getElementById('nav-list');

if (typeof mermaid !== 'undefined') {
    mermaid.initialize({
        startOnLoad: false,
        theme: 'dark',
        securityLevel: 'loose',
        fontFamily: "'Outfit', 'Inter', sans-serif"
    });
}

function renderMermaidInCard(card) {
    if (typeof mermaid === 'undefined') return;
    const codeBlocks = card.querySelectorAll('pre code');
    let found = false;

    codeBlocks.forEach(codeBlock => {
        const pre = codeBlock.closest('pre');
        if (!pre || pre.dataset.mermaidProcessed) return;

        const text = codeBlock.textContent.trim();
        const isMermaid = codeBlock.classList.contains('language-mermaid') ||
                          pre.classList.contains('language-mermaid') ||
                          text.startsWith('flowchart ') ||
                          text.startsWith('sequenceDiagram') ||
                          text.startsWith('graph ') ||
                          text.startsWith('erDiagram') ||
                          text.startsWith('classDiagram') ||
                          text.startsWith('stateDiagram') ||
                          text.startsWith('pie');

        if (isMermaid) {
            const wrapper = document.createElement('div');
            wrapper.className = 'mermaid-container';
            const mermaidDiv = document.createElement('div');
            mermaidDiv.className = 'mermaid';
            mermaidDiv.textContent = text;
            wrapper.appendChild(mermaidDiv);

            pre.dataset.mermaidProcessed = 'true';
            pre.parentNode.replaceChild(wrapper, pre);
            found = true;
        }
    });

    if (found) {
        try {
            mermaid.run();
        } catch (err) {
            console.warn('Mermaid rendering notice:', err);
        }
    }
}

async function loadPages() {
    try {
        const response = await fetch('pages/pages.json');
        if (!response.ok) throw new Error('Could not load pages.json');
        pages = await response.json();
    } catch (e) {
        console.error('Failed to load pages.json, falling back to defaults:', e);
        pages = ['01-overview.md'];
    }

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
                renderMermaidInCard(card);
                
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

    // Re-trigger mermaid if needed on current card
    const currentCard = sliderTrack.children[currentPage]?.querySelector('.content-card');
    if (currentCard) {
        renderMermaidInCard(currentCard);
    }
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
