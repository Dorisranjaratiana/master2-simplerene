"
""Racine des erreurs sémantiques du framework AXPL. Ne connaît rien du HTTP :
chaque sous-classe porte juste un #code stable (Symbol), que la couche de
transport (AXPL-HTTP) traduit en statut HTTP. Permet au moteur Ψ de rester
utilisable hors contexte web (Playground, future UI desktop) tout en donnant
à un client web des codes d'erreur stables plutôt que du texte à parser.""
"
Class {
	#name : 'AXPLApiError',
	#superclass : 'Error',
	#category : 'AXPL-Core',
	#package : 'AXPL-Core'
}

{ #category : 'accessing' }
AXPLApiError class >> code [
	^ #API_ERROR
]
