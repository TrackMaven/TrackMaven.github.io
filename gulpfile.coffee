gulp = require "gulp"
gutil = require "gulp-util"

autoprefixer = require "gulp-autoprefixer"
connect = require "gulp-connect"
imagemin = require "gulp-imagemin"
imageResize = require "gulp-image-resize"
minifyCSS = require "gulp-minify-css"
plumber = require "gulp-plumber"
pngquant = require "imagemin-pngquant"
run = require "gulp-shell"
sass = require "gulp-ruby-sass"

# Serve the generate html on localhost/localdocker:8080
gulp.task "connect", ->
    connect.server({
        root: ['output']
        port: 8080
        livereload: true
    })

# Styles for the site. Turns .scss files into a single main.css
gulp.task "scss", ->
    sass("theme/styles/main.scss", { style: 'expanded' })
        .pipe(plumber())
        .pipe(autoprefixer('last 2 version', 'safari 5', 'ie 8', 'ie 9', 'opera 12.1', 'ios 6', 'android 4'))
        .pipe(minifyCSS())
        .pipe(gulp.dest("theme/static/css"))
        .pipe(connect.reload())

# Rebuild the html.
gulp.task "html", ->
    gulp.src("output")
        .pipe(run("rm -rf output/*"))
        .pipe(run("make html"))
        .pipe(connect.reload())

# Optimises the images for web.
gulp.task "img-opt", ->
    gulp.src("images/**/*")
        .pipe(imagemin({
            progressive: true
        }))
        .pipe(gulp.dest("output/images/"))

# Optimises the images for web.
gulp.task "headshots", ->
    gulp.src("headshots/*")
        .pipe(imageResize({
            width : 200,
            height : 200,
            crop : true,
            upscale : false
        }))
        .pipe(imagemin({
            progressive: true
        }))
        .pipe(gulp.dest("output/images/headshots/"))

# Watch for any changes and run the required tasks.
gulp.task "watch", ->
    gulp.watch("theme/styles/**/*.scss", ["scss"])
    gulp.watch("theme/static/css/**/*.css", ["html"])
    gulp.watch("theme/templates/**/*.html", ["html"])
    gulp.watch("content/**/*.md", ["html", "img-opt"])

gulp.task("default", ["html", "scss", "img-opt", "watch", "connect"])
