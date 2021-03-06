class Widget::Assigned < PostDefault
  default_scope ->{ where(post_class: self.name).order(:comment_count) }
  # post_parent: sidebar_id
  # visibility: widget_id
  # comment_count: item_order
  alias_attribute :widget_id, :visibility
  alias_attribute :sidebar_id, :post_parent
  alias_attribute :item_order, :comment_count

  attr_accessible :widget_id, :sidebar_id, :item_order

  has_many :metas, ->{ where(object_class: 'Widget::Assigned')}, :class_name => "Meta", foreign_key: :objectid, dependent: :destroy
  belongs_to :sidebar, class_name: "Widget::Sidebar", foreign_key: :post_parent
  belongs_to :widget, class_name: "Widget::Main", foreign_key: :visibility
  after_initialize :fix_slug2
  before_create :set_order

  def fix_slug2
    self.slug = "slug_assigned" unless self.slug.present?
  end

  private
  def set_order
    self.item_order = self.sidebar.assigned.count + 1
  end
end
