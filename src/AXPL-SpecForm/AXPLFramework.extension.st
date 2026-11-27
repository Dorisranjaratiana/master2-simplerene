Extension { #name : 'AXPLFramework' }

{ #category : '*AXPL-SpecForm' }
AXPLFramework >> specFormPresenterAt: aLevel [
	"Le formulaire de ce niveau, dessiné par Spec-Form (au lieu d'AXPLSpecVisitor)."
	^ AXPLSpecFormPresenter on: self level: aLevel
]
