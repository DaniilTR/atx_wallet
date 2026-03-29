import json
from app.utils.text import normalize_question
from app.rag.knowledge_base import kb
out = {
  'norm_crypta': normalize_question('что такое крипта?'),
  'norm_crypto': normalize_question('Что такое криптовалюта?'),
  'match': getattr(kb.find_exact('что такое крипта?'), 'q', None)
}
print(json.dumps(out, ensure_ascii=False))
