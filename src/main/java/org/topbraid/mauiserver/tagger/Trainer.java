package org.topbraid.mauiserver.tagger;

import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.entopix.maui.filters.MauiFilter;
import com.entopix.maui.filters.MauiFilter.MauiFilterException;
import com.entopix.maui.main.MauiModelBuilder;
import com.entopix.maui.util.MauiDocument;
import com.entopix.maui.vocab.Vocabulary;

public class Trainer {
	private static final Logger log = LoggerFactory.getLogger(Trainer.class);
	
	private final Tagger tagger;
	private boolean locked = false;
	private Thread trainingThread = null;
	private TrainerReport report; 
	private TrainerReport previousReport; 
	
	public Trainer(Tagger tagger) {
		this(tagger, null);
	}

	public Trainer(Tagger tagger, TrainerReport report) {
		this.tagger = tagger;
		this.report = (report == null ? new TrainerReport() : report);
	}
	
	public TrainerReport getReport() {
		return report;
	}
	
	public synchronized void lock() {
		if (locked) throw new IllegalStateException();
		locked = true;
		previousReport = report;
		report = new TrainerReport();
		report.logStart();
	}
	
	public boolean isLocked() {
		return locked;
	}
	
	public boolean isFailed() {
		return report.getErrorMessage() != null;
	}
	
	/**
	 * Starts a training job that will be executed asynchronously on its own thread.
	 * @param corpus The document corpus
	 * @param skipped The number of "bad" input documents excluded from the corpus, for reporting purposes
	 */
	public void train(final List<MauiDocument> corpus, int skipped) {
		if (!locked) throw new IllegalStateException("Must lock() before train()");
		final MauiModelBuilder modelBuilder = createModelBuilder();
		report.logDocumentCounts(corpus.size(), skipped);
		trainingThread = new Thread() {
			@Override
			public void run() {
				log.debug("Training thread started");
				try {
					MauiFilter result = modelBuilder.buildModel(corpus);
					if (!Thread.currentThread().isInterrupted()) {
						done();
						tagger.setMauiModel(result, report);
					}
				} catch (MauiFilterException ex) {
					String errorMessage = "Error while training: " + ex.getMessage();
					report.logError(errorMessage);
					log.error(errorMessage, ex);
					done();
				}
				log.debug("Training thread stopped");
			}
		};
		trainingThread.start();
	}
	
	private synchronized void done() {
		report.logEnd();
		locked = false;
		trainingThread = null;
	}
	
	public synchronized void cancel() {
		if (!locked) return;
		// TODO: Find a way of actually stopping the MauiModelBuilder
		if (trainingThread != null) {
			trainingThread.interrupt();
		}
		done();
		report = previousReport;
	}
	
	protected MauiModelBuilder createModelBuilder() {
		MauiModelBuilder modelBuilder = new MauiModelBuilder();

		// Set features
		modelBuilder.setBasicFeatures(true);
		modelBuilder.setKeyphrasenessFeature(true);
		modelBuilder.setFrequencyFeatures(true);
		modelBuilder.setPositionsFeatures(true);
		modelBuilder.setLengthFeature(true);
		modelBuilder.setThesaurusFeatures(true);
		
		// change to 1 for short documents
//		modelBuilder.minNumOccur = 2;

		// Language selection stuff
		modelBuilder.documentLanguage = tagger.getConfiguration().getEffectiveLang();
		log.info("Using document language: " + modelBuilder.documentLanguage);
		modelBuilder.stemmer = tagger.getConfiguration().getStemmer();
		log.info("Using stemmer: " + modelBuilder.stemmer.getClass().getCanonicalName());
		modelBuilder.stopwords = tagger.getConfiguration().getStopwords();
		log.info("Using stopwords: " + modelBuilder.stopwords.getClass().getCanonicalName());
		
		// Vocabulary stuff
		// TODO: Get the actual vocabulary name as it is used in the Vocabulary instance
		Vocabulary vocabulary = tagger.getVocabularyMaui();
		modelBuilder.setVocabularyName("dummy.ttl");
		modelBuilder.setVocabulary(vocabulary);
		vocabulary.setStemmer(modelBuilder.stemmer);
		vocabulary.setStopwords(modelBuilder.stopwords);

		return modelBuilder;
	}
}
