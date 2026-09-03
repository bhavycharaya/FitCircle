/**
 * FitCircle Website — Main JavaScript
 * Handles: config injection, navbar scroll, FAQ accordion,
 *          scroll reveal animations, mobile menu, overtake counter
 */

document.addEventListener('DOMContentLoaded', () => {
  const cfg = window.FITCIRCLE_CONFIG;

  // ── Inject config values into DOM ─────────────────────
  document.querySelectorAll('[data-config]').forEach(el => {
    const key = el.dataset.config;
    if (cfg[key] !== undefined) el.textContent = cfg[key];
  });

  document.querySelectorAll('[data-href]').forEach(el => {
    const key = el.dataset.href;
    if (cfg[key] !== undefined) el.href = cfg[key];
  });

  // ── Navbar scroll effect ──────────────────────────────
  const navbar = document.getElementById('navbar');
  const onScroll = () => {
    navbar.classList.toggle('scrolled', window.scrollY > 20);
  };
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  // ── Mobile menu ───────────────────────────────────────
  const mobileMenu  = document.getElementById('mobileMenu');
  const menuOpen    = document.getElementById('menuOpen');
  const menuClose   = document.getElementById('menuClose');

  menuOpen?.addEventListener('click', () => mobileMenu.classList.add('open'));
  menuClose?.addEventListener('click', () => mobileMenu.classList.remove('open'));
  mobileMenu?.querySelectorAll('a').forEach(a => {
    a.addEventListener('click', () => mobileMenu.classList.remove('open'));
  });

  // ── FAQ accordion ─────────────────────────────────────
  document.querySelectorAll('.faq-question').forEach(btn => {
    btn.addEventListener('click', () => {
      const item = btn.closest('.faq-item');
      const isOpen = item.classList.contains('open');
      // close all
      document.querySelectorAll('.faq-item').forEach(i => i.classList.remove('open'));
      // toggle current
      if (!isOpen) item.classList.add('open');
    });
  });

  // ── Scroll reveal ─────────────────────────────────────
  const revealObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('visible');
        revealObserver.unobserve(entry.target);
      }
    });
  }, { threshold: 0.12 });

  document.querySelectorAll('.reveal').forEach(el => revealObserver.observe(el));

  // ── Animated overtake counter ─────────────────────────
  const overtakeEl = document.getElementById('overtakeSteps');
  if (overtakeEl) {
    let currentSteps = 10820;
    let targetSteps  = 10820;
    const aboveSteps = 12060;

    const updateOvertake = () => {
      const diff = aboveSteps - currentSteps + 1;
      const display = Math.max(diff, 0);
      overtakeEl.textContent = display.toLocaleString();
    };

    updateOvertake();

    // Demo: simulate steps increasing
    let animInterval = setInterval(() => {
      targetSteps += Math.floor(Math.random() * 50 + 10);
      if (targetSteps >= 12061) {
        clearInterval(animInterval);
        overtakeEl.closest('.overtake-message').textContent = '🥇 You overtook Dad! You\'re #1!';
        overtakeEl.closest('.overtake-message').style.animation = 'pulse-glow 0.5s ease-in-out 3';
        setTimeout(() => {
          targetSteps = 10820;
          updateOvertake();
          animInterval = setInterval(arguments.callee, 1800);
        }, 3500);
        return;
      }

      // Smooth count up
      const step = () => {
        if (currentSteps < targetSteps) {
          currentSteps = Math.min(currentSteps + Math.ceil((targetSteps - currentSteps) / 4), targetSteps);
          updateOvertake();
        }
      };
      step();
    }, 1800);
  }

  // ── Smooth scroll for nav links ───────────────────────
  document.querySelectorAll('a[href^="#"]').forEach(link => {
    link.addEventListener('click', e => {
      const target = document.querySelector(link.getAttribute('href'));
      if (target) {
        e.preventDefault();
        const offset = 80;
        const top = target.getBoundingClientRect().top + window.scrollY - offset;
        window.scrollTo({ top, behavior: 'smooth' });
      }
    });
  });

  // ── Version badge animation ───────────────────────────
  const versionBadge = document.querySelector('.download-version-badge');
  if (versionBadge) {
    versionBadge.style.animation = 'pulse-glow 3s ease-in-out infinite';
  }
});
