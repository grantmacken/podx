.PHONY: gh-push
gh-push: ## push to github then watch	
	@git push
	@sleep 5
	@if gh run watch 
	@then notify-send "run is done!"
	@else notify-send "run error!"
	@fi

.PHONY: gh-pr-merge
gh-pr-merge: .tmp/merge.txt
	@# gh run view
	@if ! [ -s $(<) ] 
	@then
	  echo 'ERR: [ $(<) ] before merging add merge msg'
		false
	@fi
	@cat $(<)
	@gh pr merge --squash --delete-branch --body-file $(<)
	@echo 'empty merge text'
	@echo '' > $(<)

.PHONY: gh-pr-create
gh-pr-create:
	@gh pr create --fill
