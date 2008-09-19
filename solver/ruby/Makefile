all: kakuro-perms-db.rb

kakuro-perms-db.rb: gen-kakuro-perms-db.rb
	ruby $< $@
	
test: all
	spec --color t/*.rb
