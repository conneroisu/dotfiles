import Alpine from "alpinejs"; // https://alpinejs.dev/start-here
import intersect from "@alpinejs/intersect"; // https://alpinejs.dev/plugins/intersect
import anchor from "@alpinejs/anchor"; // https://alpinejs.dev/plugins/anchor
import morph from "@alpinejs/morph"; // https://alpinejs.dev/plugins/morph
import mask from "@alpinejs/mask"; // https://alpinejs.dev/plugins/mask
import persist from "@alpinejs/persist"; // https://alpinejs.dev/plugins/persist
import focus from "@alpinejs/focus"; // https://alpinejs.dev/plugins/focus
import collapse from "@alpinejs/collapse"; // https://alpinejs.dev/plugins/collapse
import resize from "@alpinejs/resize"; // https://alpinejs.dev/plugins/resize
import ajax from "@imacrayon/alpine-ajax"; // https://alpine-ajax.js.org/reference

declare global {
  interface Window {
    MathJax: typeof MathJax;
    Alpine: typeof Alpine;
  }
}

Alpine.plugin(intersect);
Alpine.plugin(anchor);
Alpine.plugin(morph);
Alpine.plugin(mask);
Alpine.plugin(persist);
Alpine.plugin(focus);
Alpine.plugin(collapse);
Alpine.plugin(resize);
Alpine.plugin(ajax);

Alpine.start();