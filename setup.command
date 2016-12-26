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
