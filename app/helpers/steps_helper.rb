module StepsHelper
  def text_color_for_state(state)
    "text-#{color_for_state(state)}"
  end

  def color_for_state(state)
    css = "info"
    css = 'success' if state == 'complete'
    css = 'danger' if state == 'error'
    css = 'info' if state == 'running'
    css = 'warning' if state == 'in progress'

    return css
  end

  def image_for_state(state)
    css = 'glyphicon-ok' if state == 'complete'
    css = 'glyphicon-remove' if state == 'error'
    css = 'glyphicon-refresh' if state == 'running'
    css = 'glyphicon-repeat' if state == 'in progress'

    return "<span class='glyphicon #{css} #{text_color_for_state(state)}'></span>".html_safe
  end
end
