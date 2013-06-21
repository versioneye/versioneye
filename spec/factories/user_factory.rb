
FactoryGirl.define do
  factory :user do
    terms true
    datenerhebung true
    salt "sugar"
    password "12345"
    github_token "random-token-bla-bla"
    encrypted_password Digest::SHA2.hexdigest("sugar--12345")
  end

  factory :default_user, class: User do
    fullname "Hans Tanz"
    username "hanstanz"
    email "hans@tanz.de"
    password "password"
    salt "sugar"
    terms true
    datenerhebung true
    encrypted_password Digest::SHA2.hexdigest("sugar--password")
  end
end


