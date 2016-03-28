from fabric.api import local, env
import os

# Local path configuration (can be absolute or relative to fabfile)
env.deploy_path = 'output'
DEPLOY_PATH = env.deploy_path


def clean():
    if os.path.isdir(DEPLOY_PATH):
        local('rm -rf {deploy_path}'.format(**env))
        local('mkdir {deploy_path}'.format(**env))


def build():
    local('pelican -s app/pelicanconf.py')
    local("echo 'engineroom.trackmaven.com' > app/{}/CNAME".format(
        env.deploy_path))
    local("cp -r app/images/ app/output/images/")


def rebuild():
    clean()
    build()


def prodbuild():
    clean()
    local('pelican -s app/publishconf.py')
    local("echo 'engineroom.trackmaven.com' > app/{}/CNAME".format(
        env.deploy_path))
    local("cp -r app/images/ app/output/images/")


def push():
    prodbuild()
    local('git push origin source:source')
    local('ghp-import app/{}'.format(env.deploy_path))
    local('git push origin gh-pages:master --force')
