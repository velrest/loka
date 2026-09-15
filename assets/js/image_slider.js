export default {
  mounted() {
    this.current = 0
    this.slides = Array.from(this.el.querySelectorAll('[data-slide]'))
    this.dots = Array.from(this.el.querySelectorAll('[data-dot]'))
    this.thumbs = Array.from(this.el.querySelectorAll('[data-thumb]'))

    this.el.querySelector('[data-action="prev"]')?.addEventListener('click', e => {
      e.stopPropagation()
      this.show((this.current - 1 + this.slides.length) % this.slides.length)
    })
    this.el.querySelector('[data-action="next"]')?.addEventListener('click', e => {
      e.stopPropagation()
      this.show((this.current + 1) % this.slides.length)
    })
    this.thumbs.forEach((thumb, i) => {
      thumb.addEventListener('click', e => {
        e.stopPropagation()
        this.show(i)
      })
    })
  },
  show(i) {
    this.slides[this.current].classList.remove('opacity-100')
    this.slides[this.current].classList.add('opacity-0')
    if (this.dots[this.current]) {
      this.dots[this.current].classList.remove('bg-white', 'scale-125')
      this.dots[this.current].classList.add('bg-white/40')
    }
    if (this.thumbs[this.current]) {
      this.thumbs[this.current].classList.remove('shadow-[inset_0_0_0_1px_var(--clay-accent-700)]')
    }
    this.current = i
    this.slides[this.current].classList.remove('opacity-0')
    this.slides[this.current].classList.add('opacity-100')
    if (this.dots[this.current]) {
      this.dots[this.current].classList.remove('bg-white/40')
      this.dots[this.current].classList.add('bg-white', 'scale-125')
    }
    if (this.thumbs[this.current]) {
      this.thumbs[this.current].classList.add('shadow-[inset_0_0_0_1px_var(--clay-accent-700)]')
    }
  }
}
