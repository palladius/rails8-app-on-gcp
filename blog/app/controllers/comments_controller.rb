class CommentsController < ApplicationController
  allow_unauthenticated_access only: %i[ create ]
  before_action :set_post

  def create
    comment_params = params.expect(comment: [ :content, :commenter_name ])
    @comment = @post.comments.build(comment_params)
    @comment.user = Current.user if authenticated?
    @comment.save!
    redirect_to @post
  end

  private
    def set_post
      @post = Post.find(params.expect(:post_id))
      raise ActiveRecord::RecordNotFound unless @post.visible_to?(Current.user)
    end
end
