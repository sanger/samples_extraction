return unless ARGV.any?{|s| s.match(".json")}

tubes = 12.times.map{|i| "?p#{i}"}
samples = 12.times.map{ SecureRandom.uuid }
sanger_sample_id = 12.times{|i| "SAMPLE#{i}"}
study_name = "STDY1"

f1 = tubes.each_with_index.map{|t, i| [t, 'a', 'SampleTube']}
f2 = tubes.each_with_index.map{|t, i| [t, 'is', 'NotStarted']}
f3 = tubes.each_with_index.map{|t, i| [t, 'sample_tube', samples[i]]}
f4 = tubes.each_with_index.map{|t, i| [t, 'sanger_sample_id', sanger_sample_id[i]]}
f5 = tubes.each_with_index.map{|t, i| [t, 'study_name', study_name]}

all_assets = tubes + samples
obj= {
  create_assets: all_assets,
  add_facts: f1.concat(f2).concat(f3).concat(f4).concat(f5),
  add_assets: [tubes]
}.to_json

puts obj
