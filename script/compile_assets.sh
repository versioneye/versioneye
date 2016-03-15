export RAILS_ENV=production

mv app/assets/javascripts/scm/src .

mv config/mongoid.yml config/mongoid_save.yml
mv config/mongoid_assets.yml config/mongoid.yml

rake assets:precompile

mv config/mongoid.yml config/mongoid_assets.yml
mv config/mongoid_save.yml config/mongoid.yml

mv src app/assets/javascripts/scm/

cp app/assets/javascripts/libs/*  public/assets/libs/
cp app/assets/javascripts/plots/* public/assets/plots/
cp app/assets/images/*.png public/assets/
cp app/assets/images/*.jpg public/assets/
cp app/assets/images/*.gif public/assets/
cp app/assets/images/language/* public/assets/language/
cp app/assets/images/logos/* public/assets/logos/

export RAILS_ENV=development
