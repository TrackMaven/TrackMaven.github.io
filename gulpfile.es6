'use strict';

import gulp from 'gulp';

import autoprefixer from 'gulp-autoprefixer';
import connect from 'gulp-connect';
import minifyCSS from 'gulp-minify-css';
import run from 'gulp-shell';
import sass from 'gulp-sass';

// Serve the generated html on local(host|docker):8080
gulp.task("connect", () => {
    connect.server({
        root: ['app/output'],
        port: 8080,
        livereload: true
    });
});

// Styles for the site. Turns .scss files into a single main.css file.
gulp.task("scss", () => {
    gulp.src("app/theme/styles/main.scss")
        .pipe(sass().on('error', sass.logError))
        .pipe(autoprefixer('last 2 version', 'safari 5', 'ie 8', 'ie 9', 'opera 12.1', 'ios 6', 'android 4'))
        .pipe(minifyCSS())
        .pipe(gulp.dest("app/theme/static/css"))
        .pipe(connect.reload())
});

// Rebuild the html.
gulp.task("html", () => {
    gulp.src("")
        .pipe(run("fab rebuild -f app/fabfile.py"))
        .pipe(run("cp -r app/images/ app/output/images/"))
        .pipe(connect.reload())
});

// Watch for any changes and run the required tasks.
gulp.task("watch", () => {
    gulp.watch("app/content/**/*.md", ["html"])
    gulp.watch("app/theme/static/css/**/*.css", ["html"])
    gulp.watch("app/theme/styles/**/*.scss", ["scss"])
    gulp.watch("app/theme/templates/**/*.html", ["html"])
});

gulp.task("default", ["html", "scss", "watch", "connect"])
