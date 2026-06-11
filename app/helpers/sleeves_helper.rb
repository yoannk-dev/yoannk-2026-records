module SleevesHelper
  def sleeve_motif_tag(motif, fg)
    case motif
    when "rings"
      tag.div style: "position:absolute;inset:0;background:repeating-radial-gradient(circle at 50% 56%,#{fg} 0 3.5%,transparent 3.5% 11%);opacity:0.92"
    when "circle"
      tag.div style: "position:absolute;left:22%;top:22%;width:56%;aspect-ratio:1;border-radius:50%;background:#{fg}"
    when "split"
      tag.div style: "position:absolute;inset:0" do
        tag.div(style: "position:absolute;left:0;right:0;bottom:0;height:46%;background:#{fg}")
      end
    when "band"
      tag.div style: "position:absolute;inset:0" do
        safe_join([
          tag.div(style: "position:absolute;left:0;right:0;top:40%;height:13%;background:#{fg}"),
          tag.div(style: "position:absolute;left:0;right:0;top:58%;height:4%;background:#{fg};opacity:0.65")
        ])
      end
    when "dots"
      tag.div style: "position:absolute;inset:10%;background-image:radial-gradient(#{fg} 21%,transparent 23%);background-size:16.6% 16.6%"
    when "diag"
      tag.div style: "position:absolute;inset:0;background:linear-gradient(135deg,transparent 0 52%,#{fg} 52%)"
    when "lines"
      tag.div style: "position:absolute;left:24%;right:24%;top:30%;bottom:30%;background:repeating-linear-gradient(0deg,#{fg} 0 2.5%,transparent 2.5% 10%)"
    when "grid"
      tag.div style: "position:absolute;inset:0;background:repeating-linear-gradient(0deg,#{fg} 0 1px,transparent 1px 12.5%),repeating-linear-gradient(90deg,#{fg} 0 1px,transparent 1px 12.5%);opacity:0.8"
    else
      tag.div style: "position:absolute;left:22%;top:22%;width:56%;aspect-ratio:1;border-radius:50%;background:#{fg}"
    end
  end

  def barcode_html(code, height: 36)
    digits = (code || "0000000000000").chars
    bars = []
    digits.each_with_index do |d, i|
      n = d.to_i
      bars << { w: (n % 3) + 1, on: true }
      bars << { w: ((n + i) % 2) + 1, on: false }
      bars << { w: (n / 3 % 2) + 1, on: true }
      bars << { w: 1, on: false }
    end

    bar_divs = bars.map do |b|
      tag.div style: "width:#{b[:w] * 1.5}px;background:#{b[:on] ? 'currentColor' : 'transparent'}"
    end

    tag.div class: "barcode" do
      safe_join([
        tag.div(safe_join(bar_divs), class: "barcode-bars", style: "height:#{height}px"),
        tag.div(code, class: "barcode-digits")
      ])
    end
  end
end
