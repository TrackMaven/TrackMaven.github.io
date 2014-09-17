gulp = require "gulp"
gutil = require "gulp-util"

sass = require "gulp-ruby-sass"
plumber = require "gulp-plumber"
run = require "gulp-shell"

webserver = require "gulp-webserver"

# Serve the generate html on localhost/localdocker:8080
gulp.task "serve", ->
    gulp.src("output")
        .pipe(webserver(
            host: "0.0.0.0"
            port: 8080
            livereload: true))

# Styles for the site. Turns .scss files into a single main.css
gulp.task "scss", ->
    gulp.src("theme/styles/main.scss")
        .pipe(plumber())
        .pipe(sass())
        .pipe(gulp.dest("theme/static/css"))
        .pipe(run("make html"))

# Rebuild the html.
gulp.task "html", ->
    gulp.src("content/*")
        .pipe(run("make html"))

# Watch for any changes and run the required tasks.
gulp.task "watch", ->
    gulp.watch("theme/styles/*.scss", ["scss"])
    gulp.watch("theme/templates/**/*.html", ["html"])
    gulp.watch("content/*.md", ["html"])

gulp.task("default", ["watch", "serve"])
