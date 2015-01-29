c=dlss-dev-drh-geo
d=/home/drh/dlss-dev-drh-geo

java -cp "/usr/share/tomcat6/webapps/solr/WEB-INF/lib/*" \
  org.apache.solr.cloud.ZkCLI -cmd upconfig -zkhost 127.0.0.1:2181 \
  -confdir $d -confname $c \
  -solrhome /home/lyberadmin/solr-home

curl "http://sul-solr-a.stanford.edu/solr/admin/collections?action=CREATE&name=${c}&numShards=1&replicationFactor=3"
