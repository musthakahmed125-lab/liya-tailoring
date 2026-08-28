const initializePage = () => {
  const links = document.querySelectorAll('a[href^="#"]');

  links.forEach((link) => {
    link.addEventListener('click', (event) => {
      const targetId = link.getAttribute('href');
      if (!targetId || targetId === '#') return;

      const target = document.querySelector(targetId);
      if (!target) return;

      event.preventDefault();
      target.scrollIntoView({ behavior: 'smooth', block: 'start' });
    });
  });

  const courseLinks = document.querySelectorAll('.apply-course');
  const courseSelect = document.querySelector('#selected-course');

  const heroVideo = document.querySelector('.hero-video');
  const videoSoundButton = document.querySelector('.video-sound-button');

  videoSoundButton?.addEventListener('click', () => {
    if (!heroVideo) return;

    heroVideo.muted = !heroVideo.muted;
    videoSoundButton.textContent = heroVideo.muted ? '🔇' : '🔊';
    videoSoundButton.setAttribute('aria-label', heroVideo.muted ? 'Turn sound on' : 'Turn sound off');
    videoSoundButton.setAttribute('aria-pressed', String(!heroVideo.muted));

    if (heroVideo.paused) heroVideo.play();
  });

  courseLinks.forEach((link) => {
    link.addEventListener('click', () => {
      if (courseSelect) courseSelect.value = link.dataset.course || '';
    });
  });

  const applicationForm = document.querySelector('#application-form');
  const applicationStatus = document.querySelector('#application-status');

  applicationForm?.addEventListener('submit', (event) => {
    event.preventDefault();

    const formData = new FormData(applicationForm);
    const message = [
      'Hello Liya Tailoring, I would like to apply for a course.',
      '',
      `Name: ${formData.get('name')}`,
      `Phone: ${formData.get('phone')}`,
      `Course: ${formData.get('course')}`,
      `Message: ${formData.get('message') || 'No additional message'}`
    ].join('\n');

    if (applicationStatus) applicationStatus.textContent = 'Opening WhatsApp...';
    window.open(`https://wa.me/94726027583?text=${encodeURIComponent(message)}`, '_blank');
  });
};

initializePage();
