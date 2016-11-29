gulp = require "gulp"
gutil = require "gulp-util"

sass = require "gulp-sass"
plumber = require "gulp-plumber"
autoprefixer = require "gulp-autoprefixer"
minifyCSS = require "gulp-minify-css"
run = require "gulp-shell"

connect = require "gulp-connect"

# Serve the generate html on localhost/localdocker:8080
gulp.task "connect", ->
    connect.server({
        root: ['output']
        port: 8080
        livereload: true
    })

# Styles for the site. Turns .scss files into a single main.css
gulp.task "scss", ->
    gulp.src("theme/styles/main.scss")
        .pipe(sass().on('error', sass.logError))
        .pipe(minifyCSS())
        .pipe(gulp.dest("theme/static/css"))
        .pipe(connect.reload())

# Rebuild the html.
gulp.task "html", ->
    gulp.src("")
        .pipe(run("rm -fr output"))
        .pipe(run("make html"))
        .pipe(run("cp -r images/ output/images/"))
        .pipe(connect.reload())

# Watch for any changes and run the required tasks.
gulp.task "watch", ->
    gulp.watch("theme/styles/**/*.scss", ["scss"])
    gulp.watch("theme/static/css/**/*.css", ["html"])
    gulp.watch("theme/templates/**/*.html", ["html"])
    gulp.watch("content/**/*.md", ["html"])

gulp.task("default", ["html", "scss", "watch", "connect"])
