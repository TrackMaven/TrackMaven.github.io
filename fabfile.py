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
    local('pelican -s pelicanconf.py')
    local("echo 'engineroom.trackmaven.com' > {}/CNAME".format(
        env.deploy_path))


def rebuild():
    clean()
    build()


def regenerate():
    local('pelican -r -s pelicanconf.py')


def serve():
    local('cd {deploy_path} && python -m SimpleHTTPServer'.format(**env))


def reserve():
    build()
    serve()


def prodbuild():
    clean()
    local('pelican -s publishconf.py')
    local("echo 'engineroom.trackmaven.com' > {}/CNAME".format(
        env.deploy_path))


def push():
    prodbuild()
    local('git push origin source:source')
    local('ghp-import {}'.format(env.deploy_path))
    local('git push origin gh-pages:master --force')
