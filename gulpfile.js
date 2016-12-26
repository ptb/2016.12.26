// -- require ---------------------------------------------------------------

const gulp = require("gulp")
const path = require("path")
const plug = require("gulp-load-plugins")({
  "pattern": "*",
  "rename": {
    "eslint": "Eslint",
    "gulp-if": "gulpIf"
  }
})
const proc = require("child_process")

// -- const -----------------------------------------------------------------

const EXT = "xhtml"
const CWD = process.cwd()
const SRC = path.join(CWD, "code")
const TMP = path.join(CWD, "copy")
const OUT = path.join(CWD, "docs")

// -- opts ------------------------------------------------------------------

const opts = new function () {
  return {
    "autoprefixer": {
      "browsers": plug.browserslist([">0.25% in my stats"], {
        "stats": ".caniuse.json"
      }),
      "cascade": false,
      "remove": true
    },
    "babel": {
      "plugins": ["check-es2015-constants",
        "transform-es2015-arrow-functions",
        "transform-es2015-block-scoped-functions",
        "transform-es2015-block-scoping", "transform-es2015-classes",
        "transform-es2015-computed-properties",
        "transform-es2015-destructuring",
        "transform-es2015-duplicate-keys", "transform-es2015-for-of",
        "transform-es2015-function-name", "transform-es2015-literals",
        "transform-es2015-object-super", "transform-es2015-parameters",
        "transform-es2015-shorthand-properties",
        "transform-es2015-spread", "transform-es2015-sticky-regex",
        "transform-es2015-template-literals",
        "transform-es2015-typeof-symbol",
        "transform-es2015-unicode-regex", "transform-regenerator"]
    },
    "changedInPlace": {
      "firstPass": true
    },
    "cssbeautify": {
      "autosemicolon": true,
      "indent": "  "
    },
    "csslint": {
      "adjoining-classes": false,
      "box-model": true,
      "box-sizing": false,
      "bulletproof-font-face": true,
      "compatible-vendor-prefixes": false,
      "display-property-grouping": true,
      "duplicate-background-images": true,
      "duplicate-properties": true,
      "empty-rules": true,
      "fallback-colors": true,
      "floats": true,
      "font-faces": true,
      "font-sizes": true,
      "gradients": true,
      "ids": true,
      "import": true,
      "important": true,
      "known-properties": true,
      "order-alphabetical": false,
      "outline-none": true,
      "overqualified-elements": true,
      "qualified-headings": true,
      "regex-selectors": true,
      "shorthand": true,
      "star-property-hack": true,
      "text-indent": true,
      "underscore-property-hack": true,
      "unique-headings": true,
      "universal-selector": true,
      "unqualified-attributes": true,
      "vendor-prefix": true,
      "zero-units": true
    },
    "cssnano": {
      "autoprefixer": {
        "add": true,
        "browsers": plug.browserslist([">0.25% in my stats"], {
          "stats": ".caniuse.json"
        })
      }
    },
    "eslint": {
      "fix": true
    },
    "ext": {
      "es6": "*.@(e|j)s?(6|x)",
      "riot": "*.tag",
      "sass": "*.s@(a|c)ss",
      "slim": "*.sl?(i)m",
      "svg": "*.svg"
    },
    "htmlmin": function (min) {
      return {
        "collapseWhitespace": min,
        "keepClosingSlash": true,
        "minifyURLs": true,
        "removeComments": true,
        "removeScriptTypeAttributes": true,
        "removeStyleLinkTypeAttributes": true,
        "useShortDoctype": true
      }
    },
    "htmltidy": {
      "doctype": "html5",
      "indent": true,
      "indent-spaces": 2,
      "input-xml": true,
      "logical-emphasis": true,
      "new-blocklevel-tags": "",
      "output-xhtml": true,
      "quiet": true,
      "sort-attributes": "alpha",
      "tidy-mark": false,
      "wrap": 78
    },
    "jsbeautifier": {
      "js": {
        "file_types": [".es6", ".js", ".json"],
        "break_chained_methods": true,
        "end_with_newline": true,
        "indent_size": 2,
        "jslint_happy": true,
        "keep_array_indentation": true,
        "keep_function_indentation": true,
        "max_preserve_newlines": 2,
        "space_after_anon_function": true,
        "wrap_line_length": 78
      }
    },
    "rename": {
      "html": {
        "extname": `.${EXT}`
      }
    },
    "restart": {
      "args": ["-e", 'activate app "Terminal"', "-e",
        'tell app "System Events" to keystroke "k" using command down'],
      "files": ["config.rb", "gulpfile.js", "package.json", "yarn.lock"]
    },
    "sass": function (min) {
      return {
        "outputStyle": min ? "compressed" : "expanded"
      }
    },
    "slim": function (min) {
      return {
        "chdir": true,
        "options": ["attr_quote='\"'", `format=:${EXT}`, "shortcut={ " +
          "'.' => { attr: 'class' }, '@' => { attr: 'role' }, " +
          "'&' => { attr: 'type', tag: 'input' }, '#' => { attr: 'id' }, " +
          "'%' => { attr: 'itemprop' }, '^' => { attr: 'data-is' } }",
          "sort_attrs=true"],
        "pretty": !min,
        "require": "slim/include"
      }
    },
    "trimlines": {
      "leading": false
    },
    "watch": {
      "ignoreInitial": false
    }
  }
}()

// -- tidy ------------------------------------------------------------------

const tidy = {
  "code": function (files, base) {
    return gulp.src(files, {
      "base": base
    })
      .pipe(plug.changedInPlace(opts.changedInPlace))
      .pipe(plug.trimlines(opts.trimlines))
  },
  "es6": function () {
    return plug.lazypipe()
      .pipe(plug.jsbeautifier, opts.jsbeautifier)
      .pipe(plug.jsbeautifier.reporter)
      .pipe(plug.eslint, opts.eslint)
      .pipe(plug.eslint.format)
  },
  "sass": function () {
    return plug.lazypipe()
      .pipe(plug.csscomb)
      .pipe(plug.sassLint)
      .pipe(plug.sassLint.format)
  },
  "slim": function () {
    return plug.flatmap(function (stream, file) {
      proc.spawn("slim-lint", [file.path], {
        "stdio": "inherit"
      })
      return stream
    })
  }
}

// -- task ------------------------------------------------------------------

const task = {
  "css": function (min, tag) {
    return plug.lazypipe()
      .pipe(plug.autoprefixer, opts.autoprefixer)
      .pipe(plug.gulpIf, !min, plug.cssbeautify(opts.cssbeautify))
      .pipe(plug.gulpIf, !min, plug.csslint(opts.csslint))
      .pipe(plug.gulpIf, !min, plug.csslint.formatter("compact"))
      .pipe(plug.gulpIf, tag, plug.indent())
      .pipe(plug.gulpIf, min, plug.cssnano(opts.cssnano))
      .pipe(plug.gulpIf, tag && !min, plug.injectString.prepend("\n"))
      .pipe(plug.gulpIf, tag, plug.injectString.prepend("<style>"))
      .pipe(plug.gulpIf, tag, plug.injectString.append("</style"))
      .pipe(plug.gulpIf, tag && !min, plug.injectString.append("\n"))
      .pipe(plug.gulpIf, tag, plug.indent())
  },
  "html": function (lint, min, tag) {
    return plug.lazypipe()
      .pipe(plug.rename, opts.rename.html)
      .pipe(plug.gulpIf, !min, plug.htmltidy(opts.htmltidy))
      .pipe(plug.gulpIf, lint, plug.w3cjs())
      .pipe(plug.gulpIf, min, plug.htmlmin(opts.htmlmin(min)))
      .pipe(plug.gulpIf, tag, plug.indent())
  },
  "js": function (min, tag) {
    return plug.lazypipe()
      .pipe(plug.gulpIf, !min, plug.jsbeautifier(opts.jsbeautifier))
      .pipe(plug.gulpIf, !min, plug.eslint(opts.eslint))
      .pipe(plug.gulpIf, tag, plug.indent())
      .pipe(plug.gulpIf, min, plug.uglify())
      .pipe(plug.gulpIf, tag && !min, plug.injectString.prepend("\n"))
      .pipe(plug.gulpIf, tag, plug.injectString.prepend("<script>"))
      .pipe(plug.gulpIf, tag, plug.injectString.append("</script"))
      .pipe(plug.gulpIf, tag && !min, plug.injectString.append("\n"))
      .pipe(plug.gulpIf, tag, plug.indent())
  },
  "svg": function (min, tag) {
    return plug.lazypipe()
      .pipe(plug.gulpIf, !min, plug.htmltidy(opts.htmltidy))
      .pipe(plug.gulpIf, min, plug.svgmin())
      .pipe(plug.gulpIf, tag, plug.indent())
  }
}

// -- gulp ------------------------------------------------------------------

gulp.task("default", function serve (done) {
  gulp.watch(opts.restart.files)
    .on("change", function () {
      if (process.platform === "darwin") {
        proc.spawn("osascript", opts.restart.args)
      }
      plug.kexec(process.argv.shift(), process.argv)
    })

  gulp.watch(path.join(SRC, "**", opts.ext.es6), opts.watch)
    .on("all", function (evt, file) {
      var es6 = tidy.code(file, SRC)
        .pipe(tidy.es6()())

      if (["add", "change"].includes(evt)) {
        es6.pipe(gulp.dest(SRC))
          .pipe(plug.ignore.exclude(opts.ext.riot))
        es6.pipe(plug.clone())
          .pipe(plug.babel(opts.babel))
          .pipe(task.js(false, false)())
          .pipe(gulp.dest(TMP))
        es6.pipe(plug.clone())
          .pipe(plug.babel(opts.babel))
          .pipe(task.js(true, false)())
          .pipe(gulp.dest(OUT))
      }
    })

  gulp.watch(path.join(SRC, "**", opts.ext.riot, "*"), opts.watch)
    .on("all", function (evt, file) {
      var riot = function (dir, base, min) {
        return plug.streamqueue.obj(
          gulp.src(path.join(dir, opts.ext.slim), {
            "base": base
          })
          .pipe(plug.slim(opts.slim(min)))
          .pipe(task.html(false, min, true)()),

          gulp.src(path.join(dir, opts.ext.svg), {
            "base": base
          })
          .pipe(task.svg(min, true)()),

          gulp.src(path.join(dir, opts.ext.sass), {
            "base": base
          })
          .pipe(plug.sass(opts.sass(min)))
          .pipe(task.css(min, true)()),

          gulp.src(path.join(dir, opts.ext.es6), {
            "base": base
          })
          .pipe(plug.babel(opts.babel))
          .pipe(task.js(min, true)())
        )
      }

      if (["add", "change"].includes(evt)) {
        riot(path.dirname(file), SRC, false)
          .pipe(gulp.dest(TMP))
        riot(path.dirname(file), SRC, true)
          .pipe(gulp.dest(OUT))
      }
    })

  gulp.watch(path.join(SRC, "**", opts.ext.sass), opts.watch)
    .on("all", function (evt, file) {
      var sass = tidy.code(file, SRC)
        .pipe(tidy.sass()())

      if (["add", "change"].includes(evt)) {
        sass.pipe(gulp.dest(SRC))
          .pipe(plug.ignore.exclude(opts.ext.riot))
        sass.pipe(plug.clone())
          .pipe(plug.sass(opts.sass(false)))
          .pipe(task.css(false, false)())
          .pipe(gulp.dest(TMP))
        sass.pipe(plug.clone())
          .pipe(plug.sass(opts.sass(true)))
          .pipe(task.css(true, false)())
          .pipe(gulp.dest(OUT))
      }
    })

  gulp.watch(path.join(SRC, "**", opts.ext.slim), opts.watch)
    .on("all", function (evt, file) {
      var slim = tidy.code(file, SRC)
        .pipe(tidy.slim())

      if (["add", "change"].includes(evt)) {
        slim.pipe(gulp.dest(SRC))
      }
    })

  gulp.watch(path.join(SRC, "**", opts.ext.svg), opts.watch)
    .on("all", function (evt, file) {
      var svg = tidy.code(file, SRC)

      if (["add", "change"].includes(evt)) {
        svg.pipe(plug.clone())
          .pipe(task.svg(false, false)())
          .pipe(gulp.dest(SRC))
          .pipe(plug.ignore.exclude(opts.ext.riot))
          .pipe(gulp.dest(TMP))
        svg.pipe(plug.clone())
          .pipe(task.svg(true, false)())
          .pipe(gulp.dest(OUT))
      }
    })

  done()
})
