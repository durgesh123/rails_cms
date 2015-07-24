class PostType < TermTaxonomy
  default_scope { where(taxonomy: :post_type) }

  has_many :metas, ->{ where(object_class: 'PostType')}, :class_name => "Meta", foreign_key: :objectid, dependent: :destroy
  has_many :categories, :class_name => "Category", foreign_key: :parent_id, dependent: :destroy
  has_many :post_tags, :class_name => "PostTag", foreign_key: :parent_id, dependent: :destroy
  has_many :post_relationships, :class_name => "PostRelationship", dependent: :destroy, :foreign_key => :term_taxonomy_id, inverse_of: :post_type
  has_many :posts, foreign_key: :objectid, through: :post_relationships, :source => :posts, dependent: :destroy
  has_many :field_group_taxonomy, -> {where("object_class LIKE ?","PostType_%")}, :class_name => "CustomField", foreign_key: :objectid, dependent: :destroy

  belongs_to :owner, class_name: "User", foreign_key: :user_id
  belongs_to :site, :class_name => "Site", foreign_key: :parent_id

  scope :visible_menu, -> {where(term_group: nil)}
  scope :hidden_menu, -> {where(term_group: -1)}
  before_destroy :destroy_field_groups
  after_create :set_default_site_user_roles


  def manage_categories?
    options[:has_category]
  end

  # hide or show this post type on admin -> contents -> menu
  # true => enable, false => disable
  def toggle_show_for_admin_menu(flag)
    self.update(term_group: flag == true ? nil : -1)
  end

  # check if this post type is shown on admin -> contents -> menu
  def show_for_admin_menu?
    self.term_group == nil
  end

  # check if this post type manage post tags
  def manage_tags?
    options[:has_tags]
  end

  # assign settings for this post type
  # default: {has_category: false, has_tags: false, has_summary: false, has_content: true, has_comments: false, has_picture: true, has_template: false, has_keywords: false}.merge(settings)
  def set_settings(settings = {})
    settings = {has_category: false, has_tags: false, has_summary: true, has_content: true, has_comments: false, has_picture: true, has_template: false, has_keywords: true}.merge(settings)
    self.set_meta("_default", settings)
  end

  # set or update a setting for this post type
  def set_setting(key, value)
    self.set_option(key, value)
  end

  # object: [category, post, post_tags]
  def field_object_values(key, object)
    field = fields.where(slug: key).first
    field.present? ? field.values.where(objectid: object.id, object_class: object.class.to_s.gsub("Decorator","")).pluck(:value) : []
  end
  def field_object_value(key, object)
    field_object_values(key, object).first
  end

  def get_post_content(key)
    posts.rewhere(post_type: key)
  end

  # select full_categories for the post type, include all children categories
  def full_categories
    s = self.site
    Category.where("term_group = ? or status in (?)", s.id, s.post_types.pluck(:id).to_s)
  end

  # return default category for this post type
  # only return a category for post types that manage categories
  def default_category
    if manage_categories?
      cat = self.categories.find_by_slug("uncategorized")
      unless cat.present?
        cat = self.categories.create({name: 'Uncategorized', slug: 'uncategorized', parent: self.id})
        cat.set_option("not_deleted", true)
      end
      cat
    end
  end

  private
  def set_default_site_user_roles
    self.site.set_default_user_roles(self)
  end

  # destroy all custom field groups assigned to this post type
  def destroy_field_groups
    self.get_field_groups.destroy_all
  end

end
