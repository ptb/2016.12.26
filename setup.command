#!/bin/sh
CWD="$(cd -P -- "$(dirname -- "$0")" && pwd -P)"
PROJ="$(basename -- "${CWD}")"
SITE="ptb2.me"

EXT="xhtml"
SRC="code"
TMP="copy"
OUT="docs"

A="a"
C="c"
F="f"
I="i"
J="j"
P="_"

cd "${CWD}"

if [ ! -d "${CWD}/.git" ]; then
  curl -fsSL "https://api.github.com/repos/ptb/autokeep/tarball/master" \
    | tar -C "${CWD}" --strip-components 1 -xz
  sh "${CWD}/initialize.command"
fi

mkdir -p "${CWD}/data" "${CWD}/help" "${CWD}/logs" "${CWD}/${SRC}/${A}" \
  "${CWD}/${SRC}/${C}" "${CWD}/${SRC}/${F}" "${CWD}/${SRC}/${I}" \
  "${CWD}/${SRC}/${J}" "${CWD}/${SRC}/${P}" "${CWD}/${TMP}" "${CWD}/${OUT}"

printf "%s\n" '*' '!.gitignore' > "${CWD}/${TMP}/.gitignore"
touch "${CWD}/${SRC}/.keep" "${CWD}/data/.keep" "${CWD}/${OUT}/.keep"

cat > "${CWD}/package.json" <<-EOF
{
  "author": "Peter T Bosse II <ptb@ioutime.com> (http://ptb2.me)",
  "bugs": {
    "url": "https://github.com/ptb/${PROJ}/issues"
  },
  "dependencies": {},
  "description": "web project template",
  "devDependencies": {},
  "homepage": "https://github.com/ptb/${PROJ}#readme",
  "license": "Apache-2.0",
  "name": "${PROJ}",
  "repository": {
    "type": "git",
    "url": "git://github.com/ptb/${PROJ}.git"
  },
  "scripts": {},
  "version": "$(date '+%Y.%-m.%-e')"
}
EOF

yarn add --dev \
  github:gulpjs/gulp#4.0 \
  gulp-cli \
  gulp-load-plugins \
  npm-run-all

cat > "${CWD}/gulpfile.js" <<-EOF
// -- require ---------------------------------------------------------------

const gulp = require("gulp")
const plug = require("gulp-load-plugins")({
  "pattern": "*"
})

// -- const -----------------------------------------------------------------

// -- opts ------------------------------------------------------------------

const opts = new function () {
  return {
  }
}()

// -- tidy ------------------------------------------------------------------

const tidy = {
}

// -- task ------------------------------------------------------------------

const task = {
}

// -- gulp ------------------------------------------------------------------

gulp.task("default", function serve (done) {
  done()
})
EOF

cat <<-EOF | patch
--- package.json
+++ package.json
@@ -21 +21,5 @@
-  "scripts": {},
+  "scripts": {
+    "build:js": "gulp",
+    "install:js": "yarn install",
+    "start": "npm-run-all install:* build:*"
+  },
EOF

yarn add --dev \
  kexec

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -5,4 +5,5 @@
   "pattern": "*"
 })
+const proc = require("child_process")

 // -- const -----------------------------------------------------------------
@@ -12,4 +13,9 @@
 const opts = new function () {
   return {
+    "restart": {
+      "args": ["-e", 'activate app "Terminal"', "-e",
+        'tell app "System Events" to keystroke "k" using command down'],
+      "files": ["config.rb", "gulpfile.js", "package.json", "yarn.lock"]
+    }
   }
 }()
@@ -28,4 +34,12 @@

 gulp.task("default", function serve (done) {
+  gulp.watch(opts.restart.files)
+    .on("change", function () {
+      if (process.platform === "darwin") {
+        proc.spawn("osascript", opts.restart.args)
+      }
+      plug.kexec(process.argv.shift(), process.argv)
+    })
+
   done()
 })
EOF

yarn add --dev \
  gulp-changed-in-place \
  gulp-trimlines \
  lazypipe

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -2,4 +2,5 @@

 const gulp = require("gulp")
+const path = require("path")
 const plug = require("gulp-load-plugins")({
   "pattern": "*"
@@ -9,12 +10,27 @@
 // -- const -----------------------------------------------------------------

+const CWD = process.cwd()
+const SRC = path.join(CWD, "${SRC}")
+
 // -- opts ------------------------------------------------------------------

 const opts = new function () {
   return {
+    "changedInPlace": {
+      "firstPass": true
+    },
+    "ext": {
+      "slim": "*.sl?(i)m"
+    },
     "restart": {
       "args": ["-e", 'activate app "Terminal"', "-e",
         'tell app "System Events" to keystroke "k" using command down'],
       "files": ["config.rb", "gulpfile.js", "package.json", "yarn.lock"]
+    },
+    "trimlines": {
+      "leading": false
+    },
+    "watch": {
+      "ignoreInitial": false
     }
   }
@@ -24,4 +40,11 @@

 const tidy = {
+  "code": function (files, base) {
+    return gulp.src(files, {
+      "base": base
+    })
+      .pipe(plug.changedInPlace(opts.changedInPlace))
+      .pipe(plug.trimlines(opts.trimlines))
+  }
 }

@@ -42,4 +65,13 @@
     })

+  gulp.watch(path.join(SRC, "**", opts.ext.slim), opts.watch)
+    .on("all", function (evt, file) {
+      var slim = tidy.code(file, SRC)
+
+      if (["add", "change"].includes(evt)) {
+        slim.pipe(gulp.dest(SRC))
+      }
+    })
+
   done()
 })
EOF

cat > "${CWD}/.rubocop.yml" <<-EOF
AllCops:
  TargetRubyVersion: 2.4

Style/AlignParameters:
  EnforcedStyle: with_fixed_indentation

Metrics/LineLength:
  Max: 80
EOF

cat > "${CWD}/Gemfile" <<-EOF
ruby '2.4.0'

source 'https://rubygems.org'

gem 'bundler', '~> 1.13'
gem 'rubocop', '~> 0.46', require: false
gem 'slim', '~> 3.0'
gem 'slim_lint', '~> 0.8'
EOF

cat <<-EOF | patch
--- package.json
+++ package.json
@@ -26,4 +26,5 @@
     "build:js": "gulp",
     "install:js": "yarn install",
+    "install:rb": "bundle install",
     "start": "npm-run-all install:* build:*"
   },
EOF

cat > "${CWD}/.slim-lint.yml" <<-EOF
linters:
  TagCase:
    enabled: false

skip_frontmatter: true
EOF

yarn add --dev \
  gulp-flatmap

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -46,4 +46,12 @@
       .pipe(plug.changedInPlace(opts.changedInPlace))
       .pipe(plug.trimlines(opts.trimlines))
+  },
+  "slim": function () {
+    return plug.flatmap(function (stream, file) {
+      proc.spawn("slim-lint", [file.path], {
+        "stdio": "inherit"
+      })
+      return stream
+    })
   }
 }
@@ -68,4 +76,5 @@
     .on("all", function (evt, file) {
       var slim = tidy.code(file, SRC)
+        .pipe(tidy.slim())

       if (["add", "change"].includes(evt)) {
EOF

yarn add --dev \
  gulp-slim

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -10,4 +10,5 @@
 // -- const -----------------------------------------------------------------

+const EXT = "${EXT}"
 const CWD = process.cwd()
 const SRC = path.join(CWD, "${SRC}")
@@ -28,4 +29,16 @@
       "files": ["config.rb", "gulpfile.js", "package.json", "yarn.lock"]
     },
+    "slim": function (min) {
+      return {
+        "chdir": true,
+        "options": ["attr_quote='\"'", \`format=:\${EXT}\`, "shortcut={ " +
+          "'.' => { attr: 'class' }, '@' => { attr: 'role' }, " +
+          "'&' => { attr: 'type', tag: 'input' }, '#' => { attr: 'id' }, " +
+          "'%' => { attr: 'itemprop' }, '^' => { attr: 'data-is' } }",
+          "sort_attrs=true"],
+        "pretty": !min,
+        "require": "slim/include"
+      }
+    },
     "trimlines": {
       "leading": false
EOF

yarn add --dev \
  gulp-rename

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -24,4 +24,9 @@
       "slim": "*.sl?(i)m"
     },
+    "rename": {
+      "html": {
+        "extname": \`.\${EXT}\`
+      }
+    },
     "restart": {
       "args": ["-e", 'activate app "Terminal"', "-e",
@@ -73,4 +78,8 @@

 const task = {
+  "html": function () {
+    return plug.lazypipe()
+      .pipe(plug.rename, opts.rename.html)
+  }
 }

EOF

yarn add --dev \
  gulp-htmltidy \
  gulp-if

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -4,5 +4,8 @@
 const path = require("path")
 const plug = require("gulp-load-plugins")({
-  "pattern": "*"
+  "pattern": "*",
+  "rename": {
+    "gulp-if": "gulpIf"
+  }
 })
 const proc = require("child_process")
@@ -24,4 +27,17 @@
       "slim": "*.sl?(i)m"
     },
+    "htmltidy": {
+      "doctype": "html5",
+      "indent": true,
+      "indent-spaces": 2,
+      "input-xml": true,
+      "logical-emphasis": true,
+      "new-blocklevel-tags": "",
+      "output-xhtml": true,
+      "quiet": true,
+      "sort-attributes": "alpha",
+      "tidy-mark": false,
+      "wrap": 78
+    },
     "rename": {
       "html": {
@@ -78,7 +94,8 @@

 const task = {
-  "html": function () {
+  "html": function (min) {
     return plug.lazypipe()
       .pipe(plug.rename, opts.rename.html)
+      .pipe(plug.gulpIf, !min, plug.htmltidy(opts.htmltidy))
   }
 }
EOF

yarn add --dev \
  gulp-w3cjs

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -94,8 +94,9 @@

 const task = {
-  "html": function (min) {
+  "html": function (lint, min) {
     return plug.lazypipe()
       .pipe(plug.rename, opts.rename.html)
       .pipe(plug.gulpIf, !min, plug.htmltidy(opts.htmltidy))
+      .pipe(plug.gulpIf, lint, plug.w3cjs())
   }
 }
EOF

yarn add --dev \
  gulp-htmlmin

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -27,4 +27,15 @@
       "slim": "*.sl?(i)m"
     },
+    "htmlmin": function (min) {
+      return {
+        "collapseWhitespace": min,
+        "keepClosingSlash": true,
+        "minifyURLs": true,
+        "removeComments": true,
+        "removeScriptTypeAttributes": true,
+        "removeStyleLinkTypeAttributes": true,
+        "useShortDoctype": true
+      }
+    },
     "htmltidy": {
       "doctype": "html5",
@@ -99,4 +110,5 @@
       .pipe(plug.gulpIf, !min, plug.htmltidy(opts.htmltidy))
       .pipe(plug.gulpIf, lint, plug.w3cjs())
+      .pipe(plug.gulpIf, min, plug.htmlmin(opts.htmlmin(min)))
   }
 }
EOF

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -16,4 +16,5 @@
 const CWD = process.cwd()
 const SRC = path.join(CWD, "${SRC}")
+const TMP = path.join(CWD, "${TMP}")

 // -- opts ------------------------------------------------------------------
@@ -25,5 +26,6 @@
     },
     "ext": {
-      "slim": "*.sl?(i)m"
+      "slim": "*.sl?(i)m",
+      "svg": "*.svg"
     },
     "htmlmin": function (min) {
@@ -111,4 +113,8 @@
       .pipe(plug.gulpIf, lint, plug.w3cjs())
       .pipe(plug.gulpIf, min, plug.htmlmin(opts.htmlmin(min)))
+  },
+  "svg": function (min) {
+    return plug.lazypipe()
+      .pipe(plug.gulpIf, !min, plug.htmltidy(opts.htmltidy))
   }
 }
@@ -135,4 +141,16 @@
     })

+  gulp.watch(path.join(SRC, "**", opts.ext.svg), opts.watch)
+    .on("all", function (evt, file) {
+      var svg = tidy.code(file, SRC)
+
+      if (["add", "change"].includes(evt)) {
+        svg.pipe(plug.clone())
+          .pipe(task.svg(false)())
+          .pipe(gulp.dest(SRC))
+          .pipe(gulp.dest(TMP))
+      }
+    })
+
   done()
 })
EOF

yarn add --dev \
  gulp-clone \
  gulp-svgmin

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -17,4 +17,5 @@
 const SRC = path.join(CWD, "${SRC}")
 const TMP = path.join(CWD, "${TMP}")
+const OUT = path.join(CWD, "${OUT}")

 // -- opts ------------------------------------------------------------------
@@ -117,4 +118,5 @@
     return plug.lazypipe()
       .pipe(plug.gulpIf, !min, plug.htmltidy(opts.htmltidy))
+      .pipe(plug.gulpIf, min, plug.svgmin())
   }
 }
@@ -150,4 +152,7 @@
           .pipe(gulp.dest(SRC))
           .pipe(gulp.dest(TMP))
+        svg.pipe(plug.clone())
+          .pipe(task.svg(true)())
+          .pipe(gulp.dest(OUT))
       }
     })
EOF

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -27,4 +27,5 @@
     },
     "ext": {
+      "sass": "*.s@(a|c)ss",
       "slim": "*.sl?(i)m",
       "svg": "*.svg"
@@ -133,4 +134,13 @@
     })

+  gulp.watch(path.join(SRC, "**", opts.ext.sass), opts.watch)
+    .on("all", function (evt, file) {
+      var sass = tidy.code(file, SRC)
+
+      if (["add", "change"].includes(evt)) {
+        sass.pipe(gulp.dest(SRC))
+      }
+    })
+
   gulp.watch(path.join(SRC, "**", opts.ext.slim), opts.watch)
     .on("all", function (evt, file) {
EOF

cat > "${CWD}/.csscomb.json" <<-EOF
{
  "always-semicolon": true,
  "block-indent": "  ",
  "color-case": "lower",
  "color-shorthand": true,
  "element-case": "lower",
  "eof-newline": false,
  "exclude": [
    ".bundle/**",
    ".git/**",
    "node_modules/**"
  ],
  "leading-zero": true,
  "quotes": "double",
  "remove-empty-rulesets": true,
  "sort-order": [
    [
      "-webkit-rtl-ordering",
      "direction",
      "unicode-bidi",
      "writing-mode",
      "text-orientation",
      "glyph-orientation-vertical",
      "text-combine-upright",
      "text-transform",
      "white-space",
      "tab-size",
      "line-break",
      "word-break",
      "hyphens",
      "word-wrap",
      "overflow-wrap",
      "text-align",
      "text-align-last",
      "text-justify",
      "word-spacing",
      "letter-spacing",
      "text-indent",
      "hanging-punctuation",
      "-webkit-nbsp-mode",
      "text-decoration",
      "text-decoration-line",
      "text-decoration-style",
      "text-decoration-color",
      "text-decoration-skip",
      "text-underline-position",
      "text-emphasis",
      "text-emphasis-style",
      "text-emphasis-color",
      "text-emphasis-position",
      "text-shadow",
      "-webkit-text-fill-color",
      "-webkit-text-stroke",
      "-webkit-text-stroke-width",
      "-webkit-text-stroke-color",
      "-webkit-text-security",
      "font",
      "font-style",
      "font-variant",
      "font-weight",
      "font-stretch",
      "font-size",
      "line-height",
      "font-family",
      "src",
      "unicode-range",
      "-webkit-text-size-adjust",
      "font-size-adjust",
      "font-synthesis",
      "font-kerning",
      "font-variant-ligatures",
      "font-variant-position",
      "font-variant-caps",
      "font-variant-numeric",
      "font-variant-alternates",
      "font-variant-east-asian",
      "font-feature-settings",
      "font-language-override",
      "list-style",
      "list-style-type",
      "list-style-position",
      "list-style-image",
      "marker-side",
      "counter-set",
      "counter-increment",
      "caption-side",
      "table-layout",
      "border-collapse",
      "-webkit-border-horizontal-spacing",
      "-webkit-border-vertical-spacing",
      "border-spacing",
      "empty-cells",
      "move-to",
      "quotes",
      "counter-increment",
      "counter-reset",
      "page-policy",
      "content",
      "crop",
      "box-sizing",
      "outline",
      "outline-color",
      "outline-style",
      "outline-width",
      "outline-offset",
      "resize",
      "text-overflow",
      "cursor",
      "caret-color",
      "nav-up",
      "nav-right",
      "nav-down",
      "nav-left",
      "-webkit-appearance",
      "-webkit-user-drag",
      "-webkit-user-modify",
      "-webkit-user-select",
      "-moz-user-select",
      "-ms-user-select",
      "pointer-events",
      "-webkit-dashboard-region",
      "-apple-dashboard-region",
      "-webkit-touch-callout",
      "position",
      "top",
      "right",
      "bottom",
      "left",
      "offset-before",
      "offset-end",
      "offset-after",
      "offset-start",
      "z-index",
      "display",
      "-webkit-margin-collapse",
      "-webkit-margin-top-collapse",
      "-webkit-margin-bottom-collapse",
      "-webkit-margin-start",
      "margin",
      "margin-top",
      "margin-right",
      "margin-bottom",
      "margin-left",
      "-webkit-padding-start",
      "padding",
      "padding-top",
      "padding-right",
      "padding-bottom",
      "padding-left",
      "width",
      "min-width",
      "max-width",
      "height",
      "min-height",
      "max-height",
      "float",
      "clear",
      "overflow",
      "overflow-x",
      "overflow-y",
      "-webkit-overflow-scrolling",
      "overflow-style",
      "marquee-style",
      "marquee-loop",
      "marquee-direction",
      "marquee-speed",
      "visibility",
      "rotation",
      "rotation-point",
      "flex-flow",
      "flex-direction",
      "flex-wrap",
      "order",
      "flex",
      "flex-grow",
      "flex-shrink",
      "flex-basis",
      "justify-content",
      "align-items",
      "align-self",
      "align-content",
      "columns",
      "column-width",
      "column-count",
      "column-gap",
      "column-rule",
      "column-rule-width",
      "column-rule-style",
      "column-rule-color",
      "break-before",
      "break-after",
      "break-inside",
      "column-span",
      "column-fill",
      "grid",
      "grid-template",
      "grid-template-columns",
      "grid-template-rows",
      "grid-template-areas",
      "grid-auto-flow",
      "grid-auto-columns",
      "grid-auto-rows",
      "grid-column",
      "grid-row",
      "grid-area",
      "grid-row-start",
      "grid-column-start",
      "grid-row-end",
      "grid-column-end",
      "grid-gap",
      "grid-column-gap",
      "grid-row-gap",
      "orphans",
      "widows",
      "box-decoration-break",
      "background",
      "background-image",
      "background-position",
      "background-size",
      "background-repeat",
      "background-attachment",
      "background-origin",
      "background-clip",
      "background-color",
      "border",
      "border-width",
      "border-style",
      "border-color",
      "border-top",
      "border-top-width",
      "border-top-style",
      "border-top-color",
      "border-right",
      "border-right-width",
      "border-right-style",
      "border-right-color",
      "border-bottom",
      "border-bottom-width",
      "border-bottom-style",
      "border-bottom-color",
      "border-left",
      "border-left-width",
      "border-left-style",
      "border-left-color",
      "border-radius",
      "border-top-left-radius",
      "border-top-right-radius",
      "border-bottom-right-radius",
      "border-bottom-left-radius",
      "border-image",
      "border-image-source",
      "border-image-slice",
      "border-image-width",
      "border-image-outset",
      "border-image-repeat",
      "box-shadow",
      "color",
      "opacity",
      "-webkit-tap-highlight-color",
      "object-fit",
      "object-position",
      "image-resolution",
      "image-orientation",
      "clip-path",
      "mask",
      "mask-image",
      "mask-mode",
      "mask-repeat",
      "mask-position",
      "mask-clip",
      "mask-origin",
      "mask-size",
      "mask-composite",
      "mask-border",
      "mask-border-source",
      "mask-border-slice",
      "mask-border-width",
      "mask-border-outset",
      "mask-border-repeat",
      "mask-border-mode",
      "mask-type",
      "clip",
      "filter",
      "transition",
      "transition-property",
      "transition-duration",
      "transition-timing-function",
      "transition-delay",
      "transform",
      "transform-origin",
      "transform-style",
      "perspective",
      "perspective-origin",
      "backface-visibility",
      "animation",
      "animation-name",
      "animation-duration",
      "animation-timing-function",
      "animation-delay",
      "animation-iteration-count",
      "animation-direction",
      "animation-fill-mode",
      "animation-play-state",
      "voice-volume",
      "voice-balance",
      "speak",
      "speak-as",
      "pause",
      "pause-before",
      "pause-after",
      "rest",
      "rest-before",
      "rest-after",
      "cue",
      "cue-before",
      "cue-after",
      "voice-family",
      "voice-rate",
      "voice-pitch",
      "voice-range",
      "voice-stress",
      "voice-duration",
      "size",
      "page",
      "zoom",
      "min-zoom",
      "max-zoom",
      "user-zoom",
      "orientation"
    ]
  ],
  "sort-order-fallback": "abc",
  "space-after-colon": " ",
  "space-after-combinator": " ",
  "space-after-opening-brace": "\n",
  "space-after-selector-delimiter": " ",
  "space-before-closing-brace": " ",
  "space-before-colon": "",
  "space-before-combinator": " ",
  "space-before-opening-brace": " ",
  "space-before-selector-delimiter": "",
  "space-between-declarations": "\n",
  "strip-spaces": true,
  "tab-size": true,
  "unitless-zero": true,
  "vendor-prefix-align": false
}
EOF

yarn add --dev \
  gulp-csscomb

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -96,4 +96,8 @@
       .pipe(plug.trimlines(opts.trimlines))
   },
+  "sass": function () {
+    return plug.lazypipe()
+      .pipe(plug.csscomb)
+  },
   "slim": function () {
     return plug.flatmap(function (stream, file) {
@@ -137,4 +141,5 @@
     .on("all", function (evt, file) {
       var sass = tidy.code(file, SRC)
+        .pipe(tidy.sass()())

       if (["add", "change"].includes(evt)) {
EOF

cat > "${CWD}/.sass-lint.yml" <<-EOF
rules:
  bem-depth: 0
  border-zero:
    - 1
    -
      convention: 0
  brace-style: 0
  class-name-format:
    - 1
    -
      allow-leading-underscore: false
      convention: hyphenatedlowercase
  clean-import-paths:
    - 1
    -
      leading-underscore: true
      filename-extension: true
  empty-args:
    - 1
    -
      include: true
  empty-line-between-blocks: 0
  extends-before-declarations: 1
  extends-before-mixins: 1
  final-newline: 0
  force-attribute-nesting: 1
  force-element-nesting: 1
  force-pseudo-nesting: 1
  function-name-format:
    - 1
    -
      allow-leading-underscore: false
      convention: hyphenatedlowercase
  hex-length:
    - 1
    -
      style: short
  hex-notation:
    - 1
    -
      style: lowercase
  id-name-format:
    - 1
    -
      allow-leading-underscore: false
      convention: hyphenatedlowercase
  indentation: 0
  leading-zero:
    - 1
    -
      include: true
  mixin-name-format:
    - 1
    -
      allow-leading-underscore: false
      convention: hyphenatedlowercase
  mixins-before-declarations: 1
  nesting-depth:
    - 1
    -
      max-depth: 3
  no-color-keywords: 1
  no-color-literals: 1
  no-css-comments: 1
  no-debug: 1
  no-duplicate-properties: 0
  no-empty-rulesets: 1
  no-extends: 0
  no-ids: 1
  no-important: 1
  no-invalid-hex: 1
  no-mergeable-selectors: 1
  no-misspelled-properties: 1
  no-qualifying-elements:
    - 1
    -
      allow-element-with-attribute: true
      allow-element-with-class: false
      allow-element-with-id: false
  no-trailing-zero: 1
  no-transition-all: 1
  no-url-protocols: 1
  no-vendor-prefixes: 0
  no-warn: 1
  one-declaration-per-line: 1
  placeholder-in-extend: 0
  placeholder-name-format:
    - 1
    -
      allow-leading-underscore: false
      convention: hyphenatedlowercase
  property-sort-order:
    - 1
    -
      order:
        - -webkit-rtl-ordering
        - direction
        - unicode-bidi
        - writing-mode
        - text-orientation
        - glyph-orientation-vertical
        - text-combine-upright
        - text-transform
        - white-space
        - tab-size
        - line-break
        - word-break
        - hyphens
        - word-wrap
        - overflow-wrap
        - text-align
        - text-align-last
        - text-justify
        - word-spacing
        - letter-spacing
        - text-indent
        - hanging-punctuation
        - -webkit-nbsp-mode
        - text-decoration
        - text-decoration-line
        - text-decoration-style
        - text-decoration-color
        - text-decoration-skip
        - text-underline-position
        - text-emphasis
        - text-emphasis-style
        - text-emphasis-color
        - text-emphasis-position
        - text-shadow
        - -webkit-text-fill-color
        - -webkit-text-stroke
        - -webkit-text-stroke-width
        - -webkit-text-stroke-color
        - -webkit-text-security
        - font
        - font-style
        - font-variant
        - font-weight
        - font-stretch
        - font-size
        - line-height
        - font-family
        - src
        - unicode-range
        - -webkit-text-size-adjust
        - font-size-adjust
        - font-synthesis
        - font-kerning
        - font-variant-ligatures
        - font-variant-position
        - font-variant-caps
        - font-variant-numeric
        - font-variant-alternates
        - font-variant-east-asian
        - font-feature-settings
        - font-language-override
        - list-style
        - list-style-type
        - list-style-position
        - list-style-image
        - marker-side
        - counter-set
        - counter-increment
        - caption-side
        - table-layout
        - border-collapse
        - -webkit-border-horizontal-spacing
        - -webkit-border-vertical-spacing
        - border-spacing
        - empty-cells
        - move-to
        - quotes
        - counter-increment
        - counter-reset
        - page-policy
        - content
        - crop
        - box-sizing
        - outline
        - outline-color
        - outline-style
        - outline-width
        - outline-offset
        - resize
        - text-overflow
        - cursor
        - caret-color
        - nav-up
        - nav-right
        - nav-down
        - nav-left
        - -webkit-appearance
        - -webkit-user-drag
        - -webkit-user-modify
        - -webkit-user-select
        - -moz-user-select
        - -ms-user-select
        - pointer-events
        - -webkit-dashboard-region
        - -apple-dashboard-region
        - -webkit-touch-callout
        - position
        - top
        - right
        - bottom
        - left
        - offset-before
        - offset-end
        - offset-after
        - offset-start
        - z-index
        - display
        - -webkit-margin-collapse
        - -webkit-margin-top-collapse
        - -webkit-margin-bottom-collapse
        - -webkit-margin-start
        - margin
        - margin-top
        - margin-right
        - margin-bottom
        - margin-left
        - -webkit-padding-start
        - padding
        - padding-top
        - padding-right
        - padding-bottom
        - padding-left
        - width
        - min-width
        - max-width
        - height
        - min-height
        - max-height
        - float
        - clear
        - overflow
        - overflow-x
        - overflow-y
        - -webkit-overflow-scrolling
        - overflow-style
        - marquee-style
        - marquee-loop
        - marquee-direction
        - marquee-speed
        - visibility
        - rotation
        - rotation-point
        - flex-flow
        - flex-direction
        - flex-wrap
        - order
        - flex
        - flex-grow
        - flex-shrink
        - flex-basis
        - justify-content
        - align-items
        - align-self
        - align-content
        - columns
        - column-width
        - column-count
        - column-gap
        - column-rule
        - column-rule-width
        - column-rule-style
        - column-rule-color
        - break-before
        - break-after
        - break-inside
        - column-span
        - column-fill
        - grid
        - grid-template
        - grid-template-columns
        - grid-template-rows
        - grid-template-areas
        - grid-auto-flow
        - grid-auto-columns
        - grid-auto-rows
        - grid-column
        - grid-row
        - grid-area
        - grid-row-start
        - grid-column-start
        - grid-row-end
        - grid-column-end
        - grid-gap
        - grid-column-gap
        - grid-row-gap
        - orphans
        - widows
        - box-decoration-break
        - background
        - background-image
        - background-position
        - background-size
        - background-repeat
        - background-attachment
        - background-origin
        - background-clip
        - background-color
        - border
        - border-width
        - border-style
        - border-color
        - border-top
        - border-top-width
        - border-top-style
        - border-top-color
        - border-right
        - border-right-width
        - border-right-style
        - border-right-color
        - border-bottom
        - border-bottom-width
        - border-bottom-style
        - border-bottom-color
        - border-left
        - border-left-width
        - border-left-style
        - border-left-color
        - border-radius
        - border-top-left-radius
        - border-top-right-radius
        - border-bottom-right-radius
        - border-bottom-left-radius
        - border-image
        - border-image-source
        - border-image-slice
        - border-image-width
        - border-image-outset
        - border-image-repeat
        - box-shadow
        - color
        - opacity
        - -webkit-tap-highlight-color
        - object-fit
        - object-position
        - image-resolution
        - image-orientation
        - clip-path
        - mask
        - mask-image
        - mask-mode
        - mask-repeat
        - mask-position
        - mask-clip
        - mask-origin
        - mask-size
        - mask-composite
        - mask-border
        - mask-border-source
        - mask-border-slice
        - mask-border-width
        - mask-border-outset
        - mask-border-repeat
        - mask-border-mode
        - mask-type
        - clip
        - filter
        - transition
        - transition-property
        - transition-duration
        - transition-timing-function
        - transition-delay
        - transform
        - transform-origin
        - transform-style
        - perspective
        - perspective-origin
        - backface-visibility
        - animation
        - animation-name
        - animation-duration
        - animation-timing-function
        - animation-delay
        - animation-iteration-count
        - animation-direction
        - animation-fill-mode
        - animation-play-state
        - voice-volume
        - voice-balance
        - speak
        - speak-as
        - pause
        - pause-before
        - pause-after
        - rest
        - rest-before
        - rest-after
        - cue
        - cue-before
        - cue-after
        - voice-family
        - voice-rate
        - voice-pitch
        - voice-range
        - voice-stress
        - voice-duration
        - size
        - page
        - zoom
        - min-zoom
        - max-zoom
        - user-zoom
        - orientation
  property-units: 1
  quotes:
    - 1
    -
      style: double
  shorthand-values: 1
  single-line-per-selector: 0
  space-after-bang: 1
  space-after-colon: 1
  space-after-comma: 1
  space-around-operator: 1
  space-before-bang: 1
  space-before-brace: 1
  space-before-colon: 1
  space-between-parens: 1
  trailing-semicolon: 0
  url-quotes: 1
  variable-for-property: 0
  variable-name-format:
    - 1
    -
      allow-leading-underscore: false
      convention: hyphenatedlowercase
  zero-unit: 1
EOF

yarn add --dev \
  gulp-sass-lint

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -99,4 +99,6 @@
     return plug.lazypipe()
       .pipe(plug.csscomb)
+      .pipe(plug.sassLint)
+      .pipe(plug.sassLint.format)
   },
   "slim": function () {
EOF

yarn add --dev \
  gulp-sass

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -65,4 +65,9 @@
       "files": ["config.rb", "gulpfile.js", "package.json", "yarn.lock"]
     },
+    "sass": function (min) {
+      return {
+        "outputStyle": min ? "compressed" : "expanded"
+      }
+    },
     "slim": function (min) {
       return {
@@ -147,4 +152,10 @@
       if (["add", "change"].includes(evt)) {
         sass.pipe(gulp.dest(SRC))
+        sass.pipe(plug.clone())
+          .pipe(plug.sass(opts.sass(false)))
+          .pipe(gulp.dest(TMP))
+        sass.pipe(plug.clone())
+          .pipe(plug.sass(opts.sass(true)))
+          .pipe(gulp.dest(OUT))
       }
     })
EOF

cat > "${CWD}/.caniuse.json" <<-EOF
{
  "dataByBrowser": {
    "and_chr": {
      "55": 0.94975
    },
    "and_ff": {
      "50": 0
    },
    "and_uc": {
      "11": 0
    },
    "android": {
      "3": 0,
      "4": 0,
      "53": 0,
      "2.1": 0,
      "2.2": 0,
      "2.3": 0,
      "4.1": 0,
      "4.2-4.3": 0,
      "4.4": 0,
      "4.4.3-4.4.4": 0
    },
    "bb": {
      "7": 0,
      "10": 0
    },
    "chrome": {
      "4": 0,
      "5": 0,
      "6": 0,
      "7": 0,
      "8": 0,
      "9": 0,
      "10": 0,
      "11": 0,
      "12": 0,
      "13": 0,
      "14": 0,
      "15": 0,
      "16": 0,
      "17": 0,
      "18": 0,
      "19": 0,
      "20": 0,
      "21": 0,
      "22": 0,
      "23": 0,
      "24": 0.03063,
      "25": 0,
      "26": 0,
      "27": 0.03063,
      "28": 0,
      "29": 0,
      "30": 0.09191,
      "31": 0.18382,
      "32": 0.73529,
      "33": 0,
      "34": 0.09191,
      "35": 0.12254,
      "36": 0.49019,
      "37": 0,
      "38": 0,
      "39": 0.06127,
      "40": 1.5625,
      "41": 0.03063,
      "42": 0.21446,
      "43": 0.09191,
      "44": 0.03063,
      "45": 0.24509,
      "46": 0.09191,
      "47": 0.82720,
      "48": 0.24509,
      "49": 0.73529,
      "50": 1.43995,
      "51": 19.27083,
      "52": 13.32720,
      "53": 15.56372,
      "54": 19.57720,
      "55": 3.33946,
      "56": 0.24509,
      "57": 0.03063,
      "58": 0
    },
    "edge": {
      "12": 0,
      "13": 0.30637,
      "14": 0.24509,
      "15": 0.03063
    },
    "firefox": {
      "2": 0,
      "3": 0,
      "4": 0,
      "5": 0,
      "6": 0.12254,
      "7": 0,
      "8": 0,
      "9": 0,
      "10": 0,
      "11": 0,
      "12": 0,
      "13": 0,
      "14": 0,
      "15": 0,
      "16": 0,
      "17": 0,
      "18": 0,
      "19": 0,
      "20": 0,
      "21": 0.06127,
      "22": 0,
      "23": 0,
      "24": 0,
      "25": 0.09191,
      "26": 0,
      "27": 0,
      "28": 0.06127,
      "29": 0.09191,
      "30": 0,
      "31": 0,
      "32": 0,
      "33": 0,
      "34": 0.03063,
      "35": 0,
      "36": 0.03063,
      "37": 0,
      "38": 0.09191,
      "39": 0,
      "40": 0,
      "41": 0,
      "42": 0.24509,
      "43": 0.30637,
      "44": 0.06127,
      "45": 0.21446,
      "46": 0.06127,
      "47": 3.43137,
      "48": 2.11397,
      "49": 2.69607,
      "50": 1.37867,
      "51": 0.33700,
      "52": 0.15318,
      "53": 0,
      "3.5": 0,
      "3.6": 0
    },
    "ie": {
      "6": 0.09191,
      "7": 0,
      "8": 0.03063,
      "9": 0.06127,
      "10": 0.06127,
      "11": 0.58210
    },
    "ie_mob": {
      "10": 0,
      "11": 0
    },
    "ios_saf": {
      "8": 0.45955,
      "10-10.1": 0.73529,
      "3.2": 0,
      "4.0-4.1": 0,
      "4.2-4.3": 0,
      "5.0-5.1": 0.06127,
      "6.0-6.1": 0.06127,
      "7.0-7.1": 0.12254,
      "8.1-8.4": 0,
      "9.0-9.2": 0.03063,
      "9.3": 0.73529
    },
    "op_mini": {
      "all": 0
    },
    "op_mob": {
      "12": 0,
      "37": 0,
      "12.1": 0
    },
    "opera": {
      "15": 0,
      "16": 0,
      "17": 0,
      "18": 0,
      "19": 0,
      "20": 0,
      "21": 0,
      "22": 0,
      "23": 0,
      "24": 0,
      "25": 0,
      "26": 0,
      "27": 0,
      "28": 0,
      "29": 0,
      "30": 0,
      "31": 0,
      "32": 0,
      "33": 0,
      "34": 0,
      "35": 0,
      "36": 0,
      "37": 0,
      "38": 0.30637,
      "39": 0.12254,
      "40": 0,
      "41": 0.09191,
      "42": 0,
      "43": 0,
      "44": 0,
      "10.0-10.1": 0,
      "11.5": 0,
      "12.1": 0.09191
    },
    "safari": {
      "4": 0,
      "5": 0.03063,
      "6": 0,
      "7": 0.09191,
      "8": 0.03063,
      "9": 0.12254,
      "10": 1.31740,
      "3.1": 0,
      "3.2": 0,
      "5.1": 0.09191,
      "6.1": 0,
      "7.1": 0,
      "9.1": 1.25612,
      "TP": 0
    },
    "samsung": {
      "4": 0
    }
  },
  "id": "71568934|undefined",
  "meta": {
    "end_date": "2016-12-20",
    "start_date": "2016-06-20"
  },
  "name": "ptb2.me",
  "source": "google_analytics",
  "type": "custom",
  "uid": "custom.71568934|undefined"
}
EOF

yarn add --dev \
  browserslist \
  gulp-autoprefixer

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -23,4 +23,11 @@
 const opts = new function () {
   return {
+    "autoprefixer": {
+      "browsers": plug.browserslist([">0.25% in my stats"], {
+        "stats": ".caniuse.json"
+      }),
+      "cascade": false,
+      "remove": true
+    },
     "changedInPlace": {
       "firstPass": true
@@ -120,4 +127,8 @@

 const task = {
+  "css": function () {
+    return plug.lazypipe()
+      .pipe(plug.autoprefixer, opts.autoprefixer)
+  },
   "html": function (lint, min) {
     return plug.lazypipe()
@@ -154,7 +165,9 @@
         sass.pipe(plug.clone())
           .pipe(plug.sass(opts.sass(false)))
+          .pipe(task.css()())
           .pipe(gulp.dest(TMP))
         sass.pipe(plug.clone())
           .pipe(plug.sass(opts.sass(true)))
+          .pipe(task.css()())
           .pipe(gulp.dest(OUT))
       }
EOF

yarn add --dev \
  gulp-cssbeautify

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -33,4 +33,8 @@
       "firstPass": true
     },
+    "cssbeautify": {
+      "autosemicolon": true,
+      "indent": "  "
+    },
     "ext": {
       "sass": "*.s@(a|c)ss",
@@ -127,7 +131,8 @@

 const task = {
-  "css": function () {
+  "css": function (min) {
     return plug.lazypipe()
       .pipe(plug.autoprefixer, opts.autoprefixer)
+      .pipe(plug.gulpIf, !min, plug.cssbeautify(opts.cssbeautify))
   },
   "html": function (lint, min) {
@@ -165,9 +170,9 @@
         sass.pipe(plug.clone())
           .pipe(plug.sass(opts.sass(false)))
-          .pipe(task.css()())
+          .pipe(task.css(false)())
           .pipe(gulp.dest(TMP))
         sass.pipe(plug.clone())
           .pipe(plug.sass(opts.sass(true)))
-          .pipe(task.css()())
+          .pipe(task.css(true)())
           .pipe(gulp.dest(OUT))
       }
EOF

yarn add --dev \
  gulp-csslint

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -37,4 +37,38 @@
       "indent": "  "
     },
+    "csslint": {
+      "adjoining-classes": false,
+      "box-model": true,
+      "box-sizing": false,
+      "bulletproof-font-face": true,
+      "compatible-vendor-prefixes": false,
+      "display-property-grouping": true,
+      "duplicate-background-images": true,
+      "duplicate-properties": true,
+      "empty-rules": true,
+      "fallback-colors": true,
+      "floats": true,
+      "font-faces": true,
+      "font-sizes": true,
+      "gradients": true,
+      "ids": true,
+      "import": true,
+      "important": true,
+      "known-properties": true,
+      "order-alphabetical": false,
+      "outline-none": true,
+      "overqualified-elements": true,
+      "qualified-headings": true,
+      "regex-selectors": true,
+      "shorthand": true,
+      "star-property-hack": true,
+      "text-indent": true,
+      "underscore-property-hack": true,
+      "unique-headings": true,
+      "universal-selector": true,
+      "unqualified-attributes": true,
+      "vendor-prefix": true,
+      "zero-units": true
+    },
     "ext": {
       "sass": "*.s@(a|c)ss",
@@ -135,4 +169,6 @@
       .pipe(plug.autoprefixer, opts.autoprefixer)
       .pipe(plug.gulpIf, !min, plug.cssbeautify(opts.cssbeautify))
+      .pipe(plug.gulpIf, !min, plug.csslint(opts.csslint))
+      .pipe(plug.gulpIf, !min, plug.csslint.formatter("compact"))
   },
   "html": function (lint, min) {
EOF

yarn add --dev \
  gulp-cssnano

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -71,4 +71,12 @@
       "zero-units": true
     },
+    "cssnano": {
+      "autoprefixer": {
+        "add": true,
+        "browsers": plug.browserslist([">0.25% in my stats"], {
+          "stats": ".caniuse.json"
+        })
+      }
+    },
     "ext": {
       "sass": "*.s@(a|c)ss",
@@ -171,4 +179,5 @@
       .pipe(plug.gulpIf, !min, plug.csslint(opts.csslint))
       .pipe(plug.gulpIf, !min, plug.csslint.formatter("compact"))
+      .pipe(plug.gulpIf, min, plug.cssnano(opts.cssnano))
   },
   "html": function (lint, min) {
EOF

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -80,4 +80,5 @@
     },
     "ext": {
+      "es6": "*.@(e|j)s?(6|x)",
       "sass": "*.s@(a|c)ss",
       "slim": "*.sl?(i)m",
@@ -206,4 +207,13 @@
     })

+  gulp.watch(path.join(SRC, "**", opts.ext.es6), opts.watch)
+    .on("all", function (evt, file) {
+      var es6 = tidy.code(file, SRC)
+
+      if (["add", "change"].includes(evt)) {
+        es6.pipe(gulp.dest(SRC))
+      }
+    })
+
   gulp.watch(path.join(SRC, "**", opts.ext.sass), opts.watch)
     .on("all", function (evt, file) {
EOF

yarn add --dev \
  gulp-jsbeautifier

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -109,4 +109,18 @@
       "wrap": 78
     },
+    "jsbeautifier": {
+      "js": {
+        "file_types": [".es6", ".js", ".json"],
+        "break_chained_methods": true,
+        "end_with_newline": true,
+        "indent_size": 2,
+        "jslint_happy": true,
+        "keep_array_indentation": true,
+        "keep_function_indentation": true,
+        "max_preserve_newlines": 2,
+        "space_after_anon_function": true,
+        "wrap_line_length": 78
+      }
+    },
     "rename": {
       "html": {
@@ -155,4 +169,9 @@
       .pipe(plug.trimlines(opts.trimlines))
   },
+  "es6": function () {
+    return plug.lazypipe()
+      .pipe(plug.jsbeautifier, opts.jsbeautifier)
+      .pipe(plug.jsbeautifier.reporter)
+  },
   "sass": function () {
     return plug.lazypipe()
@@ -210,4 +229,5 @@
     .on("all", function (evt, file) {
       var es6 = tidy.code(file, SRC)
+        .pipe(tidy.es6()())

       if (["add", "change"].includes(evt)) {
EOF

cat > "${CWD}/.eslintignore" <<-EOF
!.eslintrc.js
!*.json
*.min.js
/docs/**/*.js
EOF

cat > "${CWD}/.eslintrc.js" <<-EOF
const INDENT_SIZE = 2

module.exports = {
  "env": {
    "amd": true,
    "browser": true,
    "commonjs": true,
    "es6": true,
    "mocha": true,
    "node": true,
    "shared-node-browser": true
  },
  "globals": {
    "document": false,
    "navigator": false,
    "window": false
  },
  "parserOptions": {
    "ecmaFeatures": {
      "experimentalObjectRestSpread": true,
      "jsx": false
    },
    "ecmaVersion": 6,
    "sourceType": "module"
  },
  "plugins": [
    "json",
    "promise",
    "standard"
  ],
  "rules": {
    "accessor-pairs": "error",
    "array-bracket-spacing": [
      "error",
      "never"
    ],
    "array-callback-return": "error",
    "arrow-body-style": [
      "error",
      "as-needed"
    ],
    "arrow-parens": [
      "error",
      "always"
    ],
    "arrow-spacing": [
      "error",
      {
        "after": true,
        "before": true
      }
    ],
    "block-scoped-var": "error",
    "block-spacing": [
      "error",
      "always"
    ],
    "brace-style": [
      "error",
      "1tbs",
      {
        "allowSingleLine": true
      }
    ],
    "callback-return": "error",
    "camelcase": [
      "error",
      {
        "properties": "always"
      }
    ],
    "comma-dangle": [
      "error",
      "never"
    ],
    "comma-spacing": [
      "error",
      {
        "after": true,
        "before": false
      }
    ],
    "comma-style": [
      "error",
      "last"
    ],
    "complexity": "off",
    "computed-property-spacing": [
      "error",
      "never"
    ],
    "consistent-return": "error",
    "consistent-this": [
      "warn",
      "self"
    ],
    "constructor-super": "error",
    "curly": [
      "error",
      "all"
    ],
    "default-case": "error",
    "dot-location": [
      "error",
      "property"
    ],
    "dot-notation": [
      "error",
      {
        "allowKeywords": false
      }
    ],
    "eol-last": [
      "error",
      "unix"
    ],
    "eqeqeq": [
      "error",
      "smart"
    ],
    "func-names": "off",
    "func-style": [
      "error",
      "expression"
    ],
    "generator-star-spacing": [
      "error",
      {
        "after": true,
        "before": true
      }
    ],
    "global-require": "error",
    "guard-for-in": "error",
    "handle-callback-err": [
      "error",
      "^(err|error)$"
    ],
    "id-blacklist": "off",
    "id-length": "off",
    "id-match": "off",
    "indent": [
      "error",
      INDENT_SIZE,
      {
        "SwitchCase": 1,
        "VariableDeclarator": 1
      }
    ],
    "init-declarations": "off",
    "jsx-quotes": [
      "error",
      "prefer-double"
    ],
    "key-spacing": [
      "error",
      {
        "afterColon": true,
        "beforeColon": false,
        "mode": "strict"
      }
    ],
    "keyword-spacing": [
      "error",
      {
        "after": true,
        "before": true
      }
    ],
    "linebreak-style": [
      "error",
      "unix"
    ],
    "lines-around-comment": [
      "error",
      {
        "afterBlockComment": false,
        "afterLineComment": false,
        "allowArrayEnd": true,
        "allowArrayStart": true,
        "allowBlockEnd": true,
        "allowBlockStart": true,
        "allowObjectEnd": true,
        "allowObjectStart": true,
        "beforeBlockComment": true,
        "beforeLineComment": true
      }
    ],
    "max-depth": "off",
    "max-len": [
      "warn",
      {
        "code": 78,
        "ignoreUrls": true
      }
    ],
    "max-nested-callbacks": "off",
    "max-params": "off",
    "max-statements": [
      "warn",
      {
        "max": 10
      }
    ],
    "max-statements-per-line": [
      "error",
      {
        "max": 1
      }
    ],
    "new-cap": [
      "error",
      {
        "capIsNew": true,
        "newIsCap": true
      }
    ],
    "new-parens": "error",
    "newline-after-var": [
      "error",
      "always"
    ],
    "newline-before-return": "off",
    "newline-per-chained-call": "error",
    "no-alert": "error",
    "no-array-constructor": "error",
    "no-bitwise": "error",
    "no-caller": "error",
    "no-case-declarations": "error",
    "no-catch-shadow": "off",
    "no-class-assign": "error",
    "no-cond-assign": "error",
    "no-confusing-arrow": [
      "error",
      {
        "allowParens": true
      }
    ],
    "no-console": "warn",
    "no-const-assign": "error",
    "no-constant-condition": "error",
    "no-continue": "error",
    "no-control-regex": "error",
    "no-debugger": "error",
    "no-delete-var": "error",
    "no-div-regex": "error",
    "no-dupe-args": "error",
    "no-dupe-class-members": "error",
    "no-dupe-keys": "error",
    "no-duplicate-case": "error",
    "no-duplicate-imports": [
      "error",
      {
        "includeExports": true
      }
    ],
    "no-else-return": "error",
    "no-empty": [
      "error",
      {
        "allowEmptyCatch": true
      }
    ],
    "no-empty-character-class": "error",
    "no-empty-function": "warn",
    "no-empty-pattern": "error",
    "no-eq-null": "error",
    "no-eval": "error",
    "no-ex-assign": "error",
    "no-extend-native": "error",
    "no-extra-bind": "error",
    "no-extra-boolean-cast": "error",
    "no-extra-label": "error",
    "no-extra-parens": [
      "error",
      "all",
      {
        "returnAssign": false
      }
    ],
    "no-extra-semi": "error",
    "no-fallthrough": "error",
    "no-floating-decimal": "error",
    "no-func-assign": "error",
    "no-implicit-coercion": "error",
    "no-implicit-globals": "error",
    "no-implied-eval": "error",
    "no-inline-comments": "error",
    "no-inner-declarations": [
      "error",
      "both"
    ],
    "no-invalid-regexp": "error",
    "no-invalid-this": "error",
    "no-irregular-whitespace": "error",
    "no-iterator": "error",
    "no-label-var": "error",
    "no-labels": [
      "error",
      {
        "allowLoop": false,
        "allowSwitch": false
      }
    ],
    "no-lone-blocks": "error",
    "no-lonely-if": "error",
    "no-loop-func": "error",
    "no-magic-numbers": [
      "warn",
      {
        "enforceConst": true,
        "ignoreArrayIndexes": true
      }
    ],
    "no-mixed-requires": [
      "error",
      {
        "allowCall": true,
        "grouping": true
      }
    ],
    "no-mixed-spaces-and-tabs": "error",
    "no-multi-spaces": "error",
    "no-multi-str": "error",
    "no-multiple-empty-lines": [
      "error",
      {
        "max": 1
      }
    ],
    "no-native-reassign": "error",
    "no-negated-condition": "error",
    "no-negated-in-lhs": "error",
    "no-nested-ternary": "error",
    "no-new": "error",
    "no-new-func": "error",
    "no-new-object": "error",
    "no-new-require": "error",
    "no-new-symbol": "error",
    "no-new-wrappers": "error",
    "no-obj-calls": "error",
    "no-octal": "error",
    "no-octal-escape": "error",
    "no-param-reassign": "error",
    "no-path-concat": "error",
    "no-plusplus": [
      "error",
      {
        "allowForLoopAfterthoughts": true
      }
    ],
    "no-process-env": "error",
    "no-process-exit": "error",
    "no-proto": "error",
    "no-redeclare": [
      "error",
      {
        "builtinGlobals": true
      }
    ],
    "no-regex-spaces": "error",
    "no-restricted-globals": "off",
    "no-restricted-imports": "off",
    "no-restricted-modules": "off",
    "no-restricted-syntax": "off",
    "no-return-assign": [
      "error",
      "always"
    ],
    "no-script-url": "error",
    "no-self-assign": "warn",
    "no-self-compare": "error",
    "no-sequences": "error",
    "no-shadow": [
      "error",
      {
        "builtinGlobals": true,
        "hoist": "all"
      }
    ],
    "no-shadow-restricted-names": "error",
    "no-spaced-func": "error",
    "no-sparse-arrays": "error",
    "no-sync": "off",
    "no-ternary": "off",
    "no-this-before-super": "error",
    "no-throw-literal": "error",
    "no-trailing-spaces": "error",
    "no-undef": "error",
    "no-undef-init": "error",
    "no-undefined": "error",
    "no-underscore-dangle": "off",
    "no-unexpected-multiline": "error",
    "no-unmodified-loop-condition": "error",
    "no-unneeded-ternary": [
      "error",
      {
        "defaultAssignment": false
      }
    ],
    "no-unreachable": "error",
    "no-unsafe-finally": "error",
    "no-unused-expressions": [
      "error",
      {
        "allowShortCircuit": true,
        "allowTernary": true
      }
    ],
    "no-unused-labels": "error",
    "no-unused-vars": [
      "error",
      {
        "args": "all",
        "argsIgnorePattern": "^_",
        "vars": "all"
      }
    ],
    "no-use-before-define": "error",
    "no-useless-call": "error",
    "no-useless-computed-key": "error",
    "no-useless-concat": "error",
    "no-useless-constructor": "error",
    "no-useless-escape": "error",
    "no-var": "off",
    "no-void": "error",
    "no-warning-comments": "warn",
    "no-whitespace-before-property": "error",
    "no-with": "error",
    "object-curly-spacing": [
      "error",
      "always",
      {
        "arraysInObjects": true,
        "objectsInObjects": true
      }
    ],
    "object-property-newline": "off",
    "object-shorthand": [
      "error",
      "always",
      {
        "avoidQuotes": true
      }
    ],
    "one-var": [
      "error",
      {
        "initialized": "never",
        "uninitialized": "always"
      }
    ],
    "one-var-declaration-per-line": "off",
    "operator-assignment": [
      "error",
      "always"
    ],
    "operator-linebreak": [
      "error",
      "after",
      {
        "overrides": {
          ":": "before",
          "?": "before"
        }
      }
    ],
    "padded-blocks": [
      "error",
      "never"
    ],
    "prefer-arrow-callback": "off",
    "prefer-const": "warn",
    "prefer-reflect": "off",
    "prefer-rest-params": "warn",
    "prefer-spread": "warn",
    "prefer-template": "error",
    "promise/param-names": "error",
    "quote-props": [
      "error",
      "always"
    ],
    "quotes": [
      "error",
      "double",
      {
        "allowTemplateLiterals": true,
        "avoidEscape": true
      }
    ],
    "radix": [
      "error",
      "always"
    ],
    "require-jsdoc": "warn",
    "require-yield": "off",
    "semi": [
      "error",
      "never"
    ],
    "semi-spacing": [
      "error",
      {
        "after": true,
        "before": false
      }
    ],
    "sort-imports": "error",
    "sort-vars": [
      "warn",
      {
        "ignoreCase": true
      }
    ],
    "space-before-blocks": [
      "error",
      "always"
    ],
    "space-before-function-paren": [
      "error",
      "always"
    ],
    "space-in-parens": [
      "error",
      "never"
    ],
    "space-infix-ops": "error",
    "space-unary-ops": [
      "error",
      {
        "nonwords": false,
        "words": true
      }
    ],
    "spaced-comment": [
      "error",
      "always",
      {
        "markers": [
          "global",
          "globals",
          "eslint",
          "eslint-disable",
          "*package",
          "!",
          ","
        ]
      }
    ],
    "standard/array-bracket-even-spacing": [
      "error",
      "either"
    ],
    "standard/computed-property-even-spacing": [
      "error",
      "even"
    ],
    "standard/object-curly-even-spacing": [
      "error",
      "either"
    ],
    "strict": [
      "error",
      "safe"
    ],
    "template-curly-spacing": [
      "error",
      "never"
    ],
    "use-isnan": "error",
    "valid-jsdoc": "warn",
    "valid-typeof": "error",
    "vars-on-top": "error",
    "wrap-iife": [
      "error",
      "any"
    ],
    "wrap-regex": "error",
    "yield-star-spacing": [
      "error",
      "both"
    ],
    "yoda": [
      "error",
      "never"
    ]
  }
}
EOF

yarn add --dev \
  eslint \
  eslint-plugin-json \
  eslint-plugin-promise \
  gulp-eslint
yarn add --dev \
  eslint-plugin-standard

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -6,4 +6,5 @@
   "pattern": "*",
   "rename": {
+    "eslint": "Eslint",
     "gulp-if": "gulpIf"
   }
@@ -79,4 +80,7 @@
       }
     },
+    "eslint": {
+      "fix": true
+    },
     "ext": {
       "es6": "*.@(e|j)s?(6|x)",
@@ -173,4 +177,6 @@
       .pipe(plug.jsbeautifier, opts.jsbeautifier)
       .pipe(plug.jsbeautifier.reporter)
+      .pipe(plug.eslint, opts.eslint)
+      .pipe(plug.eslint.format)
   },
   "sass": function () {
EOF

yarn add --dev \
  babel-preset-es2015 \
  gulp-babel

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -31,4 +31,20 @@
       "remove": true
     },
+    "babel": {
+      "plugins": ["check-es2015-constants",
+        "transform-es2015-arrow-functions",
+        "transform-es2015-block-scoped-functions",
+        "transform-es2015-block-scoping", "transform-es2015-classes",
+        "transform-es2015-computed-properties",
+        "transform-es2015-destructuring",
+        "transform-es2015-duplicate-keys", "transform-es2015-for-of",
+        "transform-es2015-function-name", "transform-es2015-literals",
+        "transform-es2015-object-super", "transform-es2015-parameters",
+        "transform-es2015-shorthand-properties",
+        "transform-es2015-spread", "transform-es2015-sticky-regex",
+        "transform-es2015-template-literals",
+        "transform-es2015-typeof-symbol",
+        "transform-es2015-unicode-regex", "transform-regenerator"]
+    },
     "changedInPlace": {
       "firstPass": true
@@ -239,4 +255,10 @@
       if (["add", "change"].includes(evt)) {
         es6.pipe(gulp.dest(SRC))
+        es6.pipe(plug.clone())
+          .pipe(plug.babel(opts.babel))
+          .pipe(gulp.dest(TMP))
+        es6.pipe(plug.clone())
+          .pipe(plug.babel(opts.babel))
+          .pipe(gulp.dest(OUT))
       }
     })
EOF

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -230,4 +230,9 @@
       .pipe(plug.gulpIf, min, plug.htmlmin(opts.htmlmin(min)))
   },
+  "js": function (min) {
+    return plug.lazypipe()
+      .pipe(plug.gulpIf, !min, plug.jsbeautifier(opts.jsbeautifier))
+      .pipe(plug.gulpIf, !min, plug.eslint(opts.eslint))
+  },
   "svg": function (min) {
     return plug.lazypipe()
@@ -257,7 +262,9 @@
         es6.pipe(plug.clone())
           .pipe(plug.babel(opts.babel))
+          .pipe(task.js(false)())
           .pipe(gulp.dest(TMP))
         es6.pipe(plug.clone())
           .pipe(plug.babel(opts.babel))
+          .pipe(task.js(true)())
           .pipe(gulp.dest(OUT))
       }
EOF

yarn add --dev \
  gulp-uglify

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -234,4 +234,5 @@
       .pipe(plug.gulpIf, !min, plug.jsbeautifier(opts.jsbeautifier))
       .pipe(plug.gulpIf, !min, plug.eslint(opts.eslint))
+      .pipe(plug.gulpIf, min, plug.uglify())
   },
   "svg": function (min) {
EOF

yarn add --dev \
  streamqueue

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -101,4 +101,5 @@
     "ext": {
       "es6": "*.@(e|j)s?(6|x)",
+      "riot": "*.tag",
       "sass": "*.s@(a|c)ss",
       "slim": "*.sl?(i)m",
@@ -272,4 +273,41 @@
     })

+  gulp.watch(path.join(SRC, "**", opts.ext.riot, "*"), opts.watch)
+    .on("all", function (evt, file) {
+      var riot = function (dir, base, min) {
+        return plug.streamqueue.obj(
+          gulp.src(path.join(dir, opts.ext.slim), {
+            "base": base
+          })
+          .pipe(plug.slim(opts.slim(min)))
+          .pipe(task.html(false, min)()),
+
+          gulp.src(path.join(dir, opts.ext.svg), {
+            "base": base
+          })
+          .pipe(task.svg(min)()),
+
+          gulp.src(path.join(dir, opts.ext.sass), {
+            "base": base
+          })
+          .pipe(plug.sass(opts.sass(min)))
+          .pipe(task.css(min)()),
+
+          gulp.src(path.join(dir, opts.ext.es6), {
+            "base": base
+          })
+          .pipe(plug.babel(opts.babel))
+          .pipe(task.js(min)())
+        )
+      }
+
+      if (["add", "change"].includes(evt)) {
+        riot(path.dirname(file), SRC, false)
+          .pipe(gulp.dest(TMP))
+        riot(path.dirname(file), SRC, true)
+          .pipe(gulp.dest(OUT))
+      }
+    })
+
   gulp.watch(path.join(SRC, "**", opts.ext.sass), opts.watch)
     .on("all", function (evt, file) {
EOF

yarn add --dev \
  gulp-ignore

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -262,4 +262,5 @@
       if (["add", "change"].includes(evt)) {
         es6.pipe(gulp.dest(SRC))
+          .pipe(plug.ignore.exclude(opts.ext.riot))
         es6.pipe(plug.clone())
           .pipe(plug.babel(opts.babel))
@@ -317,4 +318,5 @@
       if (["add", "change"].includes(evt)) {
         sass.pipe(gulp.dest(SRC))
+          .pipe(plug.ignore.exclude(opts.ext.riot))
         sass.pipe(plug.clone())
           .pipe(plug.sass(opts.sass(false)))
@@ -346,4 +348,5 @@
           .pipe(task.svg(false)())
           .pipe(gulp.dest(SRC))
+          .pipe(plug.ignore.exclude(opts.ext.riot))
           .pipe(gulp.dest(TMP))
         svg.pipe(plug.clone())
EOF

yarn add --dev \
  gulp-indent

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -216,5 +216,5 @@

 const task = {
-  "css": function (min) {
+  "css": function (min, tag) {
     return plug.lazypipe()
       .pipe(plug.autoprefixer, opts.autoprefixer)
@@ -222,7 +222,9 @@
       .pipe(plug.gulpIf, !min, plug.csslint(opts.csslint))
       .pipe(plug.gulpIf, !min, plug.csslint.formatter("compact"))
+      .pipe(plug.gulpIf, tag, plug.indent())
       .pipe(plug.gulpIf, min, plug.cssnano(opts.cssnano))
+      .pipe(plug.gulpIf, tag, plug.indent())
   },
-  "html": function (lint, min) {
+  "html": function (lint, min, tag) {
     return plug.lazypipe()
       .pipe(plug.rename, opts.rename.html)
@@ -230,15 +232,19 @@
       .pipe(plug.gulpIf, lint, plug.w3cjs())
       .pipe(plug.gulpIf, min, plug.htmlmin(opts.htmlmin(min)))
+      .pipe(plug.gulpIf, tag, plug.indent())
   },
-  "js": function (min) {
+  "js": function (min, tag) {
     return plug.lazypipe()
       .pipe(plug.gulpIf, !min, plug.jsbeautifier(opts.jsbeautifier))
       .pipe(plug.gulpIf, !min, plug.eslint(opts.eslint))
+      .pipe(plug.gulpIf, tag, plug.indent())
       .pipe(plug.gulpIf, min, plug.uglify())
+      .pipe(plug.gulpIf, tag, plug.indent())
   },
-  "svg": function (min) {
+  "svg": function (min, tag) {
     return plug.lazypipe()
       .pipe(plug.gulpIf, !min, plug.htmltidy(opts.htmltidy))
       .pipe(plug.gulpIf, min, plug.svgmin())
+      .pipe(plug.gulpIf, tag, plug.indent())
   }
 }
@@ -265,9 +271,9 @@
         es6.pipe(plug.clone())
           .pipe(plug.babel(opts.babel))
-          .pipe(task.js(false)())
+          .pipe(task.js(false, false)())
           .pipe(gulp.dest(TMP))
         es6.pipe(plug.clone())
           .pipe(plug.babel(opts.babel))
-          .pipe(task.js(true)())
+          .pipe(task.js(true, false)())
           .pipe(gulp.dest(OUT))
       }
@@ -282,10 +288,10 @@
           })
           .pipe(plug.slim(opts.slim(min)))
-          .pipe(task.html(false, min)()),
+          .pipe(task.html(false, min, true)()),

           gulp.src(path.join(dir, opts.ext.svg), {
             "base": base
           })
-          .pipe(task.svg(min)()),
+          .pipe(task.svg(min, true)()),

           gulp.src(path.join(dir, opts.ext.sass), {
@@ -293,5 +299,5 @@
           })
           .pipe(plug.sass(opts.sass(min)))
-          .pipe(task.css(min)()),
+          .pipe(task.css(min, true)()),

           gulp.src(path.join(dir, opts.ext.es6), {
@@ -299,5 +305,5 @@
           })
           .pipe(plug.babel(opts.babel))
-          .pipe(task.js(min)())
+          .pipe(task.js(min, true)())
         )
       }
@@ -321,9 +327,9 @@
         sass.pipe(plug.clone())
           .pipe(plug.sass(opts.sass(false)))
-          .pipe(task.css(false)())
+          .pipe(task.css(false, false)())
           .pipe(gulp.dest(TMP))
         sass.pipe(plug.clone())
           .pipe(plug.sass(opts.sass(true)))
-          .pipe(task.css(true)())
+          .pipe(task.css(true, false)())
           .pipe(gulp.dest(OUT))
       }
@@ -346,10 +352,10 @@
       if (["add", "change"].includes(evt)) {
         svg.pipe(plug.clone())
-          .pipe(task.svg(false)())
+          .pipe(task.svg(false, false)())
           .pipe(gulp.dest(SRC))
           .pipe(plug.ignore.exclude(opts.ext.riot))
           .pipe(gulp.dest(TMP))
         svg.pipe(plug.clone())
-          .pipe(task.svg(true)())
+          .pipe(task.svg(true, false)())
           .pipe(gulp.dest(OUT))
       }
EOF

yarn add --dev \
  gulp-inject-string

cat <<-EOF | patch
--- gulpfile.js
+++ gulpfile.js
@@ -210,4 +210,11 @@
       return stream
     })
+  },
+  "wrap": function (el, min, tag) {
+    return plug.lazypipe()
+      .pipe(plug.gulpIf, tag && !min, plug.injectString.prepend("\n"))
+      .pipe(plug.gulpIf, tag, plug.injectString.prepend(\`<\${el}>\`))
+      .pipe(plug.gulpIf, tag, plug.injectString.append(\`</\${el}>\`))
+      .pipe(plug.gulpIf, tag && !min, plug.injectString.append("\n"))
   }
 }
@@ -224,4 +231,5 @@
       .pipe(plug.gulpIf, tag, plug.indent())
       .pipe(plug.gulpIf, min, plug.cssnano(opts.cssnano))
+      .pipe(tidy.wrap, "style", min, tag)
       .pipe(plug.gulpIf, tag, plug.indent())
   },
@@ -240,4 +248,5 @@
       .pipe(plug.gulpIf, tag, plug.indent())
       .pipe(plug.gulpIf, min, plug.uglify())
+      .pipe(tidy.wrap, "script", min, tag)
       .pipe(plug.gulpIf, tag, plug.indent())
   },
EOF

cp "${CWD}/Gemfile" "${CWD}/${TMP}/.Gemfile"
cp "${CWD}/config.rb" "${CWD}/${TMP}/.config.rb"
cp "${CWD}/gulpfile.js" "${CWD}/${TMP}/.gulpfile.js"
cp "${CWD}/package.json" "${CWD}/${TMP}/.package.json"
exit 0
