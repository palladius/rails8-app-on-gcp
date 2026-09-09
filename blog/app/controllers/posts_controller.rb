class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_post, only: %i[ show edit update destroy purge_cover_image generate_podcast ]

  # GET /posts or /posts.json
  def index
    @posts = Post.with_attached_cover_image.includes(:comments, :user)
                 .where(user: Current.user)
                 .or(Post.where(public: true))
                 .or(Post.where(user_id: nil))
                 .order(created_at: :desc)
  end

  # GET /posts/1 or /posts/1.json
  def show
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts or /posts.json
  def create
    @post = Post.new(post_params)
    @post.user = Current.user

    respond_to do |format|
      if @post.save
        format.html { redirect_to @post, notice: "Post was successfully created." }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: @post.errors, status: :unprocessable_content }
      end
    end
  end

  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to @post, notice: "Post was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit, status: :unprocessable_content }
        format.json { render json: @post.errors, status: :unprocessable_content }
      end
    end
  end

  # DELETE /posts/1 or /posts/1.json
  def destroy
    @post.destroy!

    respond_to do |format|
      format.html { redirect_to posts_path, notice: "Post was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  # DELETE /posts/1/purge_cover_image
  def purge_cover_image
    @post.cover_image.purge if @post.cover_image.attached?
    GenerateCoverImageJob.perform_later(@post.id)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("post-show__hero-#{@post.id}") }
      format.html { redirect_to @post, notice: "Cover image deleted. Regenerating new cover...", status: :see_other }
    end
  end

  # POST /posts/1/generate_podcast
  def generate_podcast
    @post.podcast_audio_it.purge if @post.podcast_audio_it.attached?
    PodcastifierJob.perform_later(@post.id)

    respond_to do |format|
      format.html { redirect_to @post, notice: "🎙️ Generating AI podcast in background...", status: :see_other }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def post_params
      params.expect(post: [ :title, :body, :cover_image, :public ])
    end
end
