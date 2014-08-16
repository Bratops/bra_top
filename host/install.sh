pd=$(pwd)
pre=/usr/local/etc
mkdir $pre/nginx/sites-enabled
sudo ln -sfv $pd/nginx.conf $pre/nginx/nginx.conf
sudo ln -sfv $pd/bras $pre/nginx/sites-enabled/bras

mkdir /usr/local/etc/varnish
sudo ln -sfv $pd/varnish $pre/varnish
sudo ln -sfv $pd/bras.vcl $pre/varnish/bras.vcl
