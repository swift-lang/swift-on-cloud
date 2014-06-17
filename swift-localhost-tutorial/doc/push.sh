#! /bin/sh

# scp -r swift-cray-tutorial.html images *png login.ci.uchicago.edu:/ci/www/projects/swift/tutorials/cray

pushd .
cd ../../
tar -cvzf swift-localhost-tutorial.tar.gz swift-localhost-tutorial
mv swift-localhost-tutorial.tar.gz swift-localhost-tutorial/doc/
popd

tar zcf - --exclude-vcs *tar.gz *html *png images | ssh login.ci.uchicago.edu "cd /ci/www/projects/swift/tutorials/localhost; tar zxf -"
