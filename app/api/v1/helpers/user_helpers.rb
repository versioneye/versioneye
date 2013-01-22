module VersionEye
  module UserHelpers
    
    def make_comment_response(user, page_nr, page_size)

      comments =  Versioncomment.by_user(user).paginate(page: page_nr, 
                                                          per_page: page_size)

      comments.each_with_index do |cmd, index|
        comments[index][:user] = user
        comments[index][:product] = Product.find_by_key cmd.product_key
      end

      paging = make_paging_object(comments) 
      user_comments = Api.new comments: comments,
                               paging: paging
      present user_comments, with: Entities::VersionCommentEntities

    end

    def make_favorite_response(user, page_nr, page_size)
      favorites = user.fetch_my_products.paginate(page: page_nr, 
                                                    per_page: page_size)
      user_favorites = Api.new user: user,
                                favorites: favorites,
                                paging: make_paging_object(favorites)

      present user_favorites, with: Entities::UserFollowEntities

    end
  end
end
