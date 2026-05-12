export default {
  mounted() {
    this.current = 0
    this.slides = Array.from(this.el.querySelectorAll('[data-slide]'))
    this.dots = Array.from(this.el.querySelectorAll('[data-dot]'))

    this.el.querySelector('[data-action="prev"]')?.addEventListener('click', e => {
      e.stopPropagation()
      this.show((this.current - 1 + this.slides.length) % this.slides.length)
    })
    this.el.querySelector('[data-action="next"]')?.addEventListener('click', e => {
      e.stopPropagation()
      this.show((this.current + 1) % this.slides.length)
    })
  },
  show(i) {
    this.slides[this.current].classList.remove('opacity-100')
    this.slides[this.current].classList.add('opacity-0')
    if (this.dots[this.current]) {
      this.dots[this.current].classList.remove('bg-white', 'scale-125')
      this.dots[this.current].classList.add('bg-white/40')
    }
    this.current = i
    this.slides[this.current].classList.remove('opacity-0')
    this.slides[this.current].classList.add('opacity-100')
    if (this.dots[this.current]) {
      this.dots[this.current].classList.remove('bg-white/40')
      this.dots[this.current].classList.add('bg-white', 'scale-125')
    }
  }
}
